#!/bin/bash
#SBATCH --job-name=cg_bqsr
#SBATCH --partition=pibu_el8
#SBATCH --account=class-407009-ws-2026
#SBATCH --cpus-per-task=4
#SBATCH --mem=24G
#SBATCH --time=04:00:00
#SBATCH --output=logs/bqsr_%j.out
#SBATCH --error=logs/bqsr_%j.err
##SBATCH --reservation=class-407009-2026-10-15

# Step 08 - GATK BaseRecalibrator: model systematic base-quality errors
# using known variant sites (dbSNP, Mills/1000G indels) so real variants are
# not counted as errors. The course reads come from chr6 and chr17 only, so
# the model is built on those chromosomes (-L) to keep runtime reasonable.

set -euo pipefail

module load GATK/4.2.6.1-GCCcore-10.3.0-Java-11
module load SAMtools/1.13-GCC-10.3.0

BASE="/data/courses/cancergenomics/VAR_CALLING"
PROJECT="${PROJECT:-/data/users/$USER/CancerGenomics_Practicals}"
OUT="$PROJECT/results/alignment"

REF="$BASE/bwa_idx/genome.fa"
DBSNP="$BASE/dbsnp/GCF_000001405.40_alias.vcf.gz"
MILLS="$BASE/known_indels/resources_broad_hg38_v0_Mills_and_1000G_gold_standard.indels.hg38.vcf.gz"

test -s "$DBSNP" && test -s "$MILLS"

for SAMPLE in normal tumor; do
    IN_BAM="$OUT/${SAMPLE}_marked.bam"
    samtools quickcheck "$IN_BAM"

    gatk --java-options "-Xmx20g" BaseRecalibrator \
        -R "$REF" \
        -I "$IN_BAM" \
        -L chr6 -L chr17 \
        --known-sites "$DBSNP" \
        --known-sites "$MILLS" \
        -O "$OUT/${SAMPLE}_recal.table"

    test -s "$OUT/${SAMPLE}_recal.table"
    echo "$SAMPLE recalibration table created."
done

echo "BaseRecalibrator completed."
