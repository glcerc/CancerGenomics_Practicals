#!/bin/bash
#SBATCH --job-name=cg_bwa
#SBATCH --partition=pibu_el8
#SBATCH --account=class-407009-ws-2026
#SBATCH --cpus-per-task=8
#SBATCH --mem=32G
#SBATCH --time=08:00:00
#SBATCH --output=logs/bwa_%j.out
#SBATCH --error=logs/bwa_%j.err

set -euo pipefail

module load BWA-MEM2/2.2.1-GCC-10.3.0
module load SAMtools/1.13-GCC-10.3.0

BASE="/data/courses/cancergenomics/VAR_CALLING"
REF="$BASE/bwa_idx/genome.fa"
OUT="/data/users/gercan/CancerGenomics_Practicals/results/alignment"

mkdir -p "$OUT"

for SAMPLE in normal tumor; do
    bwa-mem2 mem -t 8 \
        -R "@RG\tID:${SAMPLE}\tSM:${SAMPLE}\tPL:ILLUMINA" \
        "$REF" \
        "$BASE/fastq/${SAMPLE}.R1.fq.gz" \
        "$BASE/fastq/${SAMPLE}.R2.fq.gz" \
        | samtools view -@ 4 -b -o "$OUT/${SAMPLE}_aligned.bam" -
done
