#!/bin/bash
#SBATCH --job-name=multiqc_cg
#SBATCH --partition=pibu_el8
#SBATCH --account=class-407009-ws-2026
#SBATCH --cpus-per-task=2
#SBATCH --mem=8G
#SBATCH --time=00:30:00
#SBATCH --output=logs/multiqc_%j.out
#SBATCH --error=logs/multiqc_%j.err
##SBATCH --reservation=class-407009-2026-10-15

# Step 04 - MultiQC: aggregate the FastQC (01-02) and fastp (03) reports for both samples into one HTML report.

set -euo pipefail

module load MultiQC/1.11-foss-2021a

PROJECT="${PROJECT:-/data/users/$USER/CancerGenomics_Practicals}"

multiqc \
    "$PROJECT/results/fastqc" \
    "$PROJECT/results/fastp" \
    --outdir "$PROJECT/results/multiqc" \
    --filename multiqc_report.html \
    --force

echo "MultiQC completed successfully."
