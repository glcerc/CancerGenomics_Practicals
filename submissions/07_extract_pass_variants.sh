#!/bin/bash
#SBATCH --job-name=extract_pass
#SBATCH --partition=pibu_el8
#SBATCH --account=class-407009-ws-2026
#SBATCH --cpus-per-task=2
#SBATCH --mem=4G
#SBATCH --time=00:30:00
#SBATCH --output=logs/extract_pass_%j.out
#SBATCH --error=logs/extract_pass_%j.err

set -euo pipefail

module load BCFtools/1.12-GCC-10.3.0

PROJECT="/data/users/gercan/CancerGenomics_Practicals"
VARIANT_DIR="$PROJECT/results/variants"

INPUT="$VARIANT_DIR/somatic.filtered.vcf.gz"
OUTPUT="$VARIANT_DIR/somatic.filtered.PASS.vcf.gz"
SUMMARY="$VARIANT_DIR/variant_counts.txt"

if [[ ! -s "$INPUT" ]]; then
    echo "ERROR: Missing filtered VCF: $INPUT" >&2
    exit 1
fi

bcftools view \
    --apply-filters PASS \
    --output-type z \
    --output "$OUTPUT" \
    "$INPUT"

bcftools index --tbi "$OUTPUT"

TOTAL=$(bcftools view -H "$INPUT" | wc -l)
PASS=$(bcftools view -H "$OUTPUT" | wc -l)

{
    echo "Total filtered VCF records: $TOTAL"
    echo "PASS VCF records: $PASS"
} | tee "$SUMMARY"

echo "PASS extraction and indexing completed."
