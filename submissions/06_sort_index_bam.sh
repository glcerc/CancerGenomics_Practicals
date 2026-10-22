#!/bin/bash
#SBATCH --job-name=cg_sort
#SBATCH --partition=pibu_el8
#SBATCH --account=class-407009-ws-2026
#SBATCH --cpus-per-task=8
#SBATCH --mem=24G
#SBATCH --time=04:00:00
#SBATCH --output=logs/sort_%j.out
#SBATCH --error=logs/sort_%j.err

set -euo pipefail

module load SAMtools/1.13-GCC-10.3.0

OUT="/data/users/gercan/CancerGenomics_Practicals/results/alignment"

for SAMPLE in normal tumor; do
    samtools sort -@ 8 \
        -o "$OUT/${SAMPLE}_sorted.bam" \
        "$OUT/${SAMPLE}_aligned.bam"

    samtools index "$OUT/${SAMPLE}_sorted.bam"
done
