#!/bin/bash
#SBATCH --job-name=filter_summary
#SBATCH --partition=pibu_el8
#SBATCH --account=class-407009-ws-2026
#SBATCH --cpus-per-task=1
#SBATCH --mem=2G
#SBATCH --time=00:15:00
#SBATCH --output=logs/filter_summary_%j.out
#SBATCH --error=logs/filter_summary_%j.err
##SBATCH --reservation=class-407009-2026-10-15

# Step 15 - Summarise why Mutect2 calls were filtered (course question:
# "What were the main reasons variants were filtered out?").

set -euo pipefail

module load BCFtools/1.12-GCC-10.3.0

PROJECT="${PROJECT:-/data/users/$USER/CancerGenomics_Practicals}"
VARIANT_DIR="$PROJECT/results/variants"

INPUT="$VARIANT_DIR/somatic.filtered.vcf.gz"
OUT_COMBINED="$VARIANT_DIR/filter_reasons_combined.tsv"
OUT_SINGLE="$VARIANT_DIR/filter_reasons_individual.tsv"
OUT_TYPES="$VARIANT_DIR/pass_variant_types.tsv"

if [[ ! -s "$INPUT" ]]; then
    echo "ERROR: Missing filtered VCF: $INPUT" >&2
    exit 1
fi

# 1) Exact FILTER strings (combinations), most frequent first.
{
    printf "count\tfilter_combination\n"
    bcftools query -f '%FILTER\n' "$INPUT" \
        | sort | uniq -c | sort -k1,1nr \
        | awk '{printf "%s\t%s\n", $1, $2}'
} > "$OUT_COMBINED"

# 2) Each individual filter flag counted once per variant it touches.
{
    printf "count\tfilter\n"
    bcftools query -f '%FILTER\n' "$INPUT" \
        | tr ';' '\n' | sort | uniq -c | sort -k1,1nr \
        | awk '{printf "%s\t%s\n", $1, $2}'
} > "$OUT_SINGLE"

# 3) SNV vs indel split among PASS calls.
{
    printf "type\tcount\n"
    printf "SNV\t%s\n" "$(bcftools view -H -f PASS -v snps "$INPUT" | wc -l)"
    printf "indel\t%s\n" "$(bcftools view -H -f PASS -v indels "$INPUT" | wc -l)"
    printf "other\t%s\n" "$(bcftools view -H -f PASS -V snps,indels "$INPUT" | wc -l)"
} > "$OUT_TYPES"

echo "Total records: $(bcftools view -H "$INPUT" | wc -l)"
echo
echo "== Individual filter flags =="
cat "$OUT_SINGLE"
echo
echo "== Filter combinations (top 15) =="
head -16 "$OUT_COMBINED"
echo
echo "== PASS variant types =="
cat "$OUT_TYPES"
echo
echo "Filter summary written to $VARIANT_DIR"
