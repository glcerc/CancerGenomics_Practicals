#!/bin/bash
#SBATCH --job-name=cg_bwa
#SBATCH --partition=pibu_el8
#SBATCH --account=class-407009-ws-2026
#SBATCH --cpus-per-task=8
#SBATCH --mem=32G
#SBATCH --time=08:00:00
#SBATCH --output=logs/bwa_%j.out
#SBATCH --error=logs/bwa_%j.err
##SBATCH --reservation=class-407009-2026-10-15

# Step 05 - Align normal and tumor paired-end reads to the reference with
# bwa-mem2 (pre-built course index), adding read groups required by GATK,
# and stream the output directly into compressed BAM.

set -euo pipefail

module load BWA-MEM2/2.2.1-GCC-10.3.0
module load SAMtools/1.13-GCC-10.3.0

BASE="/data/courses/cancergenomics/VAR_CALLING"
REF="$BASE/bwa_idx/genome.fa"
PROJECT="${PROJECT:-/data/users/$USER/CancerGenomics_Practicals}"
OUT="$PROJECT/results/alignment"

mkdir -p "$OUT"

for SAMPLE in normal tumor; do
    R1="$BASE/fastq/${SAMPLE}.R1.fq.gz"
    R2="$BASE/fastq/${SAMPLE}.R2.fq.gz"
    test -s "$R1" && test -s "$R2"

    echo "Aligning $SAMPLE"
    bwa-mem2 mem -t 8 \
        -R "@RG\tID:${SAMPLE}\tSM:${SAMPLE}\tLB:${SAMPLE}\tPL:ILLUMINA" \
        "$REF" "$R1" "$R2" \
        | samtools view -@ 2 -b -o "$OUT/${SAMPLE}_aligned.bam" -

    samtools quickcheck "$OUT/${SAMPLE}_aligned.bam"
    echo "$SAMPLE aligned."
done

echo "bwa-mem2 alignment completed."
