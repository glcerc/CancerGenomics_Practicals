#!/bin/bash
#SBATCH --job-name=cg_bqsr
#SBATCH --partition=pibu_el8
#SBATCH --account=class-407009-ws-2026
#SBATCH --cpus-per-task=4
#SBATCH --mem=24G
#SBATCH --time=04:00:00
#SBATCH --output=logs/bqsr_%j.out
#SBATCH --error=logs/bqsr_%j.err

set -euo pipefail

module load GATK/4.2.6.1-GCCcore-10.3.0-Java-11

BASE="/data/courses/cancergenomics/VAR_CALLING"
OUT="/data/users/gercan/CancerGenomics_Practicals/results/alignment"

REF="$BASE/bwa_idx/genome.fa"
DBSNP="$BASE/dbsnp/GCF_000001405.40_alias.vcf.gz"
MILLS="$BASE/known_indels/resources_broad_hg38_v0_Mills_and_1000G_gold_standard.indels.hg38.vcf.gz"

for SAMPLE in normal tumor; do
    gatk BaseRecalibrator \
        -R "$REF" \
        -I "$OUT/${SAMPLE}_marked.bam" \
        --known-sites "$DBSNP" \
        --known-sites "$MILLS" \
        -O "$OUT/${SAMPLE}_recal.table"
done
