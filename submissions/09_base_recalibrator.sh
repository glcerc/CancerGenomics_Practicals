#!/bin/bash
#SBATCH --job-name=gatk_bqsr
#SBATCH --partition=pibu_el8
#SBATCH --account=class-407009-ws-2026
#SBATCH --cpus-per-task=4
#SBATCH --mem=32G
#SBATCH --time=04:00:00
#SBATCH --output=logs/bqsr_%j.out
#SBATCH --error=logs/bqsr_%j.err

set -euo pipefail

module load GATK/4.2.6.1-GCCcore-10.3.0-Java-11

PROJECT="/data/users/gercan/CancerGenomics_Practicals"
REFDIR="/data/courses/cancergenomics/VAR_CALLING"

REF="$REFDIR/bwa_idx/genome.fa"
DBSNP="$REFDIR/dbsnp/GCF_000001405.40_alias.vcf.gz"
INDELS="$REFDIR/known_indels/resources_broad_hg38_v0_Homo_sapiens_assembly38.known_indels.vcf.gz"
MILLS="$REFDIR/known_indels/resources_broad_hg38_v0_Mills_and_1000G_gold_standard.indels.hg38.vcf.gz"

INPUT="$PROJECT/results/markduplicates"
OUTPUT="$PROJECT/results/bqsr"

mkdir -p "$OUTPUT"

for sample in normal tumor; do

    echo "=== Running BaseRecalibrator for $sample ==="

    BAM="$INPUT/${sample}_marked.bam"
    TABLE="$OUTPUT/${sample}_recal.table"

    if [[ ! -s "$BAM" ]]; then
        echo "ERROR: Missing BAM: $BAM" >&2
        exit 1
    fi

    gatk --java-options "-Xmx24g" BaseRecalibrator \
        -R "$REF" \
        -I "$BAM" \
        --known-sites "$DBSNP" \
        --known-sites "$INDELS" \
        --known-sites "$MILLS" \
        -O "$TABLE"

    echo "Completed BaseRecalibrator for $sample"

done

echo "=== BaseRecalibrator finished ==="
