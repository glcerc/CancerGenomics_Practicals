#!/bin/bash
#SBATCH --job-name=fastqc_normal
#SBATCH --partition=pibu_el8
#SBATCH --account=class-407009-ws-2026
#SBATCH --cpus-per-task=4
#SBATCH --mem=8G
#SBATCH --time=01:00:00
#SBATCH --output=logs/fastqc_normal_%j.out
#SBATCH --error=logs/fastqc_normal_%j.err

set -euo pipefail

module load FastQC/0.11.9-Java-11

PROJECT=/data/users/gercan/CancerGenomics_Practicals
FASTQ=/data/courses/cancergenomics/VAR_CALLING/fastq

mkdir -p "$PROJECT/results/fastqc/normal"

fastqc \
    --threads 4 \
    --outdir "$PROJECT/results/fastqc/normal" \
    "$FASTQ/normal.R1.fq.gz" \
    "$FASTQ/normal.R2.fq.gz"

echo "Normal FastQC completed."
