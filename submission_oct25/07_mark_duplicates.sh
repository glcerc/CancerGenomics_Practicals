#!/bin/bash
#SBATCH --job-name=cg_markdup
#SBATCH --partition=pibu_el8
#SBATCH --account=class-407009-ws-2026
#SBATCH --cpus-per-task=4
#SBATCH --mem=24G
#SBATCH --time=04:00:00
#SBATCH --output=logs/markdup_%j.out
#SBATCH --error=logs/markdup_%j.err
##SBATCH --reservation=class-407009-2026-10-15

# Step 07 - Mark PCR/optical duplicates with GATK MarkDuplicates so that
# reads from the same original DNA fragment are not counted as independent
# evidence. Duplicates are flagged (SAM flag 1024), not removed.

set -euo pipefail

module load GATK/4.2.6.1-GCCcore-10.3.0-Java-11
module load SAMtools/1.13-GCC-10.3.0

PROJECT="${PROJECT:-/data/users/$USER/CancerGenomics_Practicals}"
OUT="$PROJECT/results/alignment"

for SAMPLE in normal tumor; do
    IN_BAM="$OUT/${SAMPLE}_sorted.bam"
    OUT_BAM="$OUT/${SAMPLE}_marked.bam"
    METRICS="$OUT/${SAMPLE}_duplicate_metrics.txt"

    # Stop early if the sorted BAM from step 06 is missing or corrupt.
    samtools quickcheck "$IN_BAM"

    gatk --java-options "-Xmx20g" MarkDuplicates \
        -I "$IN_BAM" \
        -O "$OUT_BAM" \
        -M "$METRICS" \
        --CREATE_INDEX true

    samtools quickcheck "$OUT_BAM"

    # Print the duplication rate (course question), read from the metrics file.
    awk -F'\t' -v s="$SAMPLE" '
        /^LIBRARY/ { for (i = 1; i <= NF; i++) if ($i == "PERCENT_DUPLICATION") c = i; getline;
                     printf "%s duplication rate: %.2f%%\n", s, 100 * $c; exit }
    ' "$METRICS"

    # The sorted BAM is no longer needed once the marked BAM is valid.
    rm "$IN_BAM" "$IN_BAM.bai"
    echo "$SAMPLE duplicates marked."
done

echo "MarkDuplicates completed."
