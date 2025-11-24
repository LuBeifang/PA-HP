# Make QC directory
mkdir -p cutQC

# Trim single-end reads
mkdir -p cutsingle

cat singleid | xargs -P 5 -I {} bash -c '
n="{}"
trim_galore -q 20 --phred33 --stringency 3 single/raw/${n}.fastq --gzip -o ./cutsingle \
    --fastqc_args "-t 30 --outdir ./cutQC" -j 8
'

# Trim paired-end reads
mkdir -p cutpair

cat pairid | xargs -P 5 -I {} bash -c '
n="{}"
trim_galore -q 20 --paired --phred33 --stringency 3 paired/raw/${n}_1.fastq paired/raw/${n}_2.fastq --gzip -o ./cutpair \
    --fastqc_args "-t 30 --outdir ./cutQC" -j 8
'

# Align single-end reads
mkdir -p singlebam

star_align_single() {
    n=$1
    STAR --genomeDir ./ref \
         --readFilesIn ./cutsingle/${n}_trimmed.fq.gz \
         --outFileNamePrefix ./singlebam/${n} \
         --alignIntronMax 1 \
         --alignIntronMin 1 \
         --outSAMtype BAM Unsorted \
         --runThreadN 20 \
         --readFilesCommand gunzip -c
}
export -f star_align_single

cat singleid | xargs -P 10 -I {} bash -c 'star_align_single "$@"' _ {}

# Align paired-end reads
mkdir -p pairbam

star_align_pair() {
    n=$1
    STAR --genomeDir ./ref \
         --readFilesIn ./cutpair/${n}_1_val_1.fq.gz ./cutpair/${n}_2_val_2.fq.gz \
         --outFileNamePrefix ./pairbam/${n} \
         --alignIntronMax 1 \
         --alignIntronMin 1 \
         --outSAMtype BAM Unsorted \
         --runThreadN 20 \
         --readFilesCommand gunzip -c
}
export -f star_align_pair

cat pairid | xargs -P 3 -I {} bash -c 'star_align_pair "$@"' _ {}
