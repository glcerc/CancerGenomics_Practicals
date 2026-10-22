#!/bin/bash
#SBATCH --job-name=vep_offline
#SBATCH --partition=pibu_el8
#SBATCH --account=class-407009-ws-2026
#SBATCH --cpus-per-task=2
#SBATCH --mem=8G
#SBATCH --time=02:00:00
#SBATCH --output=logs/vep_offline_%j.out
#SBATCH --error=logs/vep_offline_%j.err

set -euo pipefail

PROJECT="/data/users/$USER/CancerGenomics_Practicals"

VEP_IMAGE="/data/courses/cancergenomics/2026/VEP/vep.sif"
VEP_CACHE="/data/courses/cancergenomics/2026/VEP/vep_data"

INPUT="$PROJECT/results/variants/somatic.filtered.PASS.vcf.gz"
OUTPUT="$PROJECT/results/annotation/vep_offline_annotated.vcf"

test -s "$INPUT"
test -s "$VEP_IMAGE"
test -d "$VEP_CACHE"

mkdir -p "$PROJECT/results/annotation"

singularity exec \
    --bind "$VEP_CACHE:/vep_data" \
    --bind "$PROJECT:$PROJECT" \
    "$VEP_IMAGE" vep \
    --dir /vep_data \
    --cache \
    --offline \
    --species homo_sapiens \
    --assembly GRCh38 \
    --format vcf \
    --vcf \
    --symbol \
    --canonical \
    --sift b \
    --polyphen b \
    --force_overwrite \
    --input_file "$INPUT" \
    --output_file "$OUTPUT"

echo "Offline VEP annotation completed."
