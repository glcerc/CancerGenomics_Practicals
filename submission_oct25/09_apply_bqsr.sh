#!/bin/bash
#SBATCH --job-name=cg_applybqsr
#SBATCH --partition=pibu_el8
#SBATCH --account=class-407009-ws-2026
#SBATCH --cpus-per-task=4
#SBATCH --mem=24G
#SBATCH --time=04:00:00
#SBATCH --output=logs/applybqsr_%j.out
#SBATCH --error=logs/applybqsr_%j.err
##SBATCH --reservation=class-407009-2026-10-15

# Step 09 - GATK ApplyBQSR: rewrite base qualities with the recalibration
# table from step 08, producing the final analysis-ready BAM
# (equivalent to the course-provided *.recal.bam).

set -euo pipefail

module load GATK/4.2.6.1-GCCcore-10.3.0-Java-11
module load SAMtools/1.13-GCC-10.3.0

BASE="/data/courses/cancergenomics/VAR_CALLING"
PROJECT="${PROJECT:-/data/users/$USER/CancerGenomics_Practicals}"
OUT="$PROJECT/results/alignment"
REF="$BASE/bwa_idx/genome.fa"

for SAMPLE in normal tumor; do
    IN_BAM="$OUT/${SAMPLE}_marked.bam"
    TABLE="$OUT/${SAMPLE}_recal.table"
    OUT_BAM="$OUT/${SAMPLE}_recal.bam"

    # Stop early if steps 07/08 did not produce their outputs.
    samtools quickcheck "$IN_BAM"
    test -s "$TABLE"

    gatk --java-options "-Xmx20g" ApplyBQSR \
        -R "$REF" \
        -I "$IN_BAM" \
        --bqsr-recal-file "$TABLE" \
        -O "$OUT_BAM"

    samtools quickcheck "$OUT_BAM"

    # The marked BAM (and its Picard-style .bai) is no longer needed.
    rm "$IN_BAM" "${IN_BAM%.bam}.bai"
    echo "$SAMPLE BQSR applied."
done

echo "ApplyBQSR completed."
