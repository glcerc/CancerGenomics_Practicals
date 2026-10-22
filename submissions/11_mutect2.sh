#!/bin/bash
#SBATCH --job-name=mutect2
#SBATCH --partition=pibu_el8
#SBATCH --account=class-407009-ws-2026
#SBATCH --cpus-per-task=4
#SBATCH --mem=32G
#SBATCH --time=03:00:00
#SBATCH --output=logs/mutect2_%j.out
#SBATCH --error=logs/mutect2_%j.err

set -euo pipefail

module load GATK/4.2.6.1-GCCcore-10.3.0-Java-11

BASE="/data/courses/cancergenomics/VAR_CALLING"
PROJECT="/data/users/gercan/CancerGenomics_Practicals"

REF="$BASE/reference/ref_genome.fa"
INTERVALS="$BASE/reference/exome_regions.bed.interval_list"
NORMAL="$BASE/alignments/normal.recal.bam"
TUMOR="$BASE/alignments/tumor.recal.bam"
GNOMAD="$BASE/resources/af-only-gnomad.hg38.subset.vcf.gz"
PON="$BASE/resources/1000g_pon.hg38.subset.vcf.gz"

OUT="$PROJECT/results/variants"
mkdir -p "$OUT"

gatk --java-options "-Xmx24g" Mutect2 \
    -R "$REF" \
    -L "$INTERVALS" \
    -I "$TUMOR" \
    -I "$NORMAL" \
    -normal normal \
    --germline-resource "$GNOMAD" \
    --panel-of-normals "$PON" \
    -O "$OUT/somatic.vcf.gz"

echo "Mutect2 completed successfully."
