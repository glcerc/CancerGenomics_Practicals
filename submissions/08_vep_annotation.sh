#!/bin/bash
#SBATCH --job-name=vep_annotation
#SBATCH --partition=pibu_el8
#SBATCH --account=class-407009-ws-2026
#SBATCH --cpus-per-task=2
#SBATCH --mem=8G
#SBATCH --time=02:00:00
#SBATCH --output=logs/vep_%j.out
#SBATCH --error=logs/vep_%j.err

set -euo pipefail

PROJECT="/data/users/gercan/CancerGenomics_Practicals"
ENV="$PROJECT/conda_envs/vep_env"

export PATH="$ENV/bin:$PATH"

INPUT="$PROJECT/results/variants/somatic.filtered.PASS.vcf.gz"
OUTPUT_DIR="$PROJECT/results/annotation"

mkdir -p "$OUTPUT_DIR"

test -s "$INPUT"

vep \
    --input_file "$INPUT" \
    --output_file "$OUTPUT_DIR/vep_annotated.vcf" \
    --vcf \
    --database \
    --species homo_sapiens \
    --assembly GRCh38 \
    --symbol \
    --canonical \
    --hgvs \
    --variant_class \
    --sift b \
    --polyphen b \
    --force_overwrite \
    --no_stats

echo "VEP annotation completed."
