#!/bin/bash
#SBATCH --job-name=cg_markdup
#SBATCH --partition=pibu_el8
#SBATCH --account=class-407009-ws-2026
#SBATCH --cpus-per-task=4
#SBATCH --mem=24G
#SBATCH --time=04:00:00
#SBATCH --output=logs/markdup_%j.out
#SBATCH --error=logs/markdup_%j.err

set -euo pipefail

module load GATK/4.2.6.1-GCCcore-10.3.0-Java-11

OUT="/data/users/gercan/CancerGenomics_Practicals/results/alignment"

for SAMPLE in normal tumor; do
    gatk MarkDuplicates \
        -I "$OUT/${SAMPLE}_sorted.bam" \
        -O "$OUT/${SAMPLE}_marked.bam" \
        -M "$OUT/${SAMPLE}_duplicate_metrics.txt" \
        --CREATE_INDEX true
done
