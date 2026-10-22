#!/bin/bash
#SBATCH --job-name=cg_applybqsr
#SBATCH --partition=pibu_el8
#SBATCH --account=class-407009-ws-2026
#SBATCH --cpus-per-task=4
#SBATCH --mem=24G
#SBATCH --time=04:00:00
#SBATCH --output=logs/applybqsr_%j.out
#SBATCH --error=logs/applybqsr_%j.err

set -euo pipefail

module load GATK/4.2.6.1-GCCcore-10.3.0-Java-11

BASE="/data/courses/cancergenomics/VAR_CALLING"
OUT="/data/users/gercan/CancerGenomics_Practicals/results/alignment"
REF="$BASE/bwa_idx/genome.fa"

for SAMPLE in normal tumor; do
    gatk ApplyBQSR \
        -R "$REF" \
        -I "$OUT/${SAMPLE}_marked.bam" \
        --bqsr-recal-file "$OUT/${SAMPLE}_recal.table" \
        -O "$OUT/${SAMPLE}_recal.bam"
done
