#!/bin/bash
#SBATCH --job-name=cg_sort
#SBATCH --partition=pibu_el8
#SBATCH --account=class-407009-ws-2026
#SBATCH --cpus-per-task=8
#SBATCH --mem=24G
#SBATCH --time=04:00:00
#SBATCH --output=logs/sort_%j.out
#SBATCH --error=logs/sort_%j.err
##SBATCH --reservation=class-407009-2026-10-15

# Step 06 - Coordinate-sort and index the aligned BAMs (required for
# duplicate marking, GATK tools and IGV). The unsorted BAM is removed
# after a successful sort to save disk space.

set -euo pipefail

module load SAMtools/1.13-GCC-10.3.0

PROJECT="${PROJECT:-/data/users/$USER/CancerGenomics_Practicals}"
OUT="$PROJECT/results/alignment"

for SAMPLE in normal tumor; do
    IN_BAM="$OUT/${SAMPLE}_aligned.bam"
    OUT_BAM="$OUT/${SAMPLE}_sorted.bam"
    samtools quickcheck "$IN_BAM"

    samtools sort -@ 8 -o "$OUT_BAM" "$IN_BAM"
    samtools index "$OUT_BAM"
    samtools quickcheck "$OUT_BAM"

    rm "$IN_BAM"
    echo "$SAMPLE sorted and indexed."
done

echo "Sorting and indexing completed."
