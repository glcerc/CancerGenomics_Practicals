#!/bin/bash
#SBATCH --job-name=hs_metrics
#SBATCH --partition=pibu_el8
#SBATCH --account=class-407009-ws-2026
#SBATCH --cpus-per-task=2
#SBATCH --mem=12G
#SBATCH --time=01:30:00
#SBATCH --output=logs/hs_metrics_%j.out
#SBATCH --error=logs/hs_metrics_%j.err
##SBATCH --reservation=class-407009-2026-10-15

# Step 11 - Exome capture metrics (GATK CollectHsMetrics) on the
# course-provided recalibrated BAMs: fold enrichment, on-target bases and
# target coverage, as in the course BAM QC exercise.

set -euo pipefail

module load GATK/4.2.6.1-GCCcore-10.3.0-Java-11

PROJECT="${PROJECT:-/data/users/$USER/CancerGenomics_Practicals}"
BASE="/data/courses/cancergenomics/VAR_CALLING"

REF="$BASE/reference/ref_genome.fa"
INTERVALS="$BASE/reference/exome_regions.bed.interval_list"
OUTDIR="$PROJECT/results/bam_qc"

mkdir -p "$OUTDIR"

for SAMPLE in normal tumor; do
    BAM="$BASE/alignments/${SAMPLE}.recal.bam"
    test -s "$BAM"

    # Bait and target are the same interval list in this course.
    gatk --java-options "-Xmx8g" CollectHsMetrics \
        -I "$BAM" \
        -O "$OUTDIR/${SAMPLE}_hs_metrics.txt" \
        -R "$REF" \
        --BAIT_INTERVALS "$INTERVALS" \
        --TARGET_INTERVALS "$INTERVALS"

    # Print the key numbers asked in the course exercise.
    awk -F'\t' -v s="$SAMPLE" '
        /^BAIT_SET/ { for (i = 1; i <= NF; i++) c[$i] = i; getline;
            printf "%s: fold enrichment %s, on-target %s, mean target coverage %s, 30x %s\n",
                   s, $c["FOLD_ENRICHMENT"], $c["PCT_USABLE_BASES_ON_TARGET"],
                   $c["MEAN_TARGET_COVERAGE"], $c["PCT_TARGET_BASES_30X"]; exit }
    ' "$OUTDIR/${SAMPLE}_hs_metrics.txt"
done

echo "CollectHsMetrics completed."
