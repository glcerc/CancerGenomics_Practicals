#!/bin/bash
#SBATCH --job-name=cg_bam_qc
#SBATCH --partition=pibu_el8
#SBATCH --account=class-407009-ws-2026
#SBATCH --cpus-per-task=2
#SBATCH --mem=4G
#SBATCH --time=01:00:00
#SBATCH --output=logs/bam_qc_%j.out
#SBATCH --error=logs/bam_qc_%j.err
##SBATCH --reservation=class-407009-2026-10-15

# Step 10 - BAM QC with samtools (quickcheck, flagstat, stats) on the course-provided
# recalibrated BAMs used for variant calling, plus our own BAMs from steps 05-09.

set -euo pipefail

module load SAMtools/1.13-GCC-10.3.0

PROJECT="${PROJECT:-/data/users/$USER/CancerGenomics_Practicals}"
BAMDIR="/data/courses/cancergenomics/VAR_CALLING/alignments"
OUTDIR="$PROJECT/results/bam_qc"

mkdir -p "$OUTDIR"

for SAMPLE in normal tumor; do
    BAM="$BAMDIR/${SAMPLE}.recal.bam"
    test -s "$BAM"

    samtools quickcheck -v "$BAM"
    samtools flagstat -@ 2 "$BAM" \
        > "$OUTDIR/${SAMPLE}_flagstat.txt"
    samtools stats -@ 2 "$BAM" \
        > "$OUTDIR/${SAMPLE}_stats.txt"
done

# Also QC our own BAMs from steps 05-09, if present, for comparison.
for SAMPLE in normal tumor; do
    OWN="$PROJECT/results/alignment/${SAMPLE}_recal.bam"
    [[ -s "$OWN" ]] || continue
    samtools quickcheck -v "$OWN"
    samtools flagstat -@ 2 "$OWN" > "$OUTDIR/${SAMPLE}_own_flagstat.txt"
done

echo "BAM quality control completed."
