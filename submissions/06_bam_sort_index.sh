#!/bin/bash
#SBATCH --job-name=bam_sort_index
#SBATCH --partition=pibu_el8
#SBATCH --account=class-407009-ws-2026
#SBATCH --cpus-per-task=8
#SBATCH --mem=32G
#SBATCH --time=03:00:00
#SBATCH --output=logs/bam_sort_%j.out
#SBATCH --error=logs/bam_sort_%j.err

set -euo pipefail

module load SAMtools/1.13-GCC-10.3.0

PROJECT="/data/users/gercan/CancerGenomics_Practicals"
INPUT="$PROJECT/results/alignment"
OUTPUT="$PROJECT/results/alignment"

mkdir -p "$OUTPUT"

for sample in normal tumor; do
    echo "Sorting $sample BAM"

    samtools sort \
        -@ 8 \
        -m 2G \
        -T "$OUTPUT/${sample}_sort_tmp" \
        -o "$OUTPUT/${sample}_sorted.bam" \
        "$INPUT/${sample}_aligned.bam"

    echo "Indexing $sample BAM"

    samtools index \
        -@ 8 \
        "$OUTPUT/${sample}_sorted.bam"

    samtools quickcheck -v \
        "$OUTPUT/${sample}_sorted.bam"

    echo "$sample sorting and indexing completed"
done

echo "All BAM processing completed."
