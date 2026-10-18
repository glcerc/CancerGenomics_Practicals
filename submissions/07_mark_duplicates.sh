#!/bin/bash
#SBATCH --job-name=gatk_markdup
#SBATCH --partition=pibu_el8
#SBATCH --account=class-407009-ws-2026
#SBATCH --cpus-per-task=4
#SBATCH --mem=32G
#SBATCH --time=03:00:00
#SBATCH --output=logs/markdup_%j.out
#SBATCH --error=logs/markdup_%j.err

set -euo pipefail

module load GATK/4.2.6.1-GCCcore-10.3.0-Java-11
module load SAMtools/1.13-GCC-10.3.0

PROJECT="/data/users/gercan/CancerGenomics_Practicals"
INPUT="$PROJECT/results/alignment"
OUTPUT="$PROJECT/results/markduplicates"

mkdir -p "$OUTPUT"

for sample in normal tumor; do

    echo "Starting MarkDuplicates: $sample"

    gatk --java-options "-Xmx24g -Djava.io.tmpdir=$OUTPUT" \
        MarkDuplicates \
        -I "$INPUT/${sample}_sorted.bam" \
        -O "$OUTPUT/${sample}_marked.bam" \
        -M "$OUTPUT/${sample}_dup_metrics.txt" \
        --CREATE_INDEX true \
        --VALIDATION_STRINGENCY LENIENT

    echo "Checking marked BAM: $sample"

    samtools quickcheck -v \
        "$OUTPUT/${sample}_marked.bam"

    echo "$sample completed successfully"

done

echo "All MarkDuplicates analyses completed."
