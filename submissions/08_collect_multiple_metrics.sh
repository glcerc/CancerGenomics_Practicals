#!/bin/bash
#SBATCH --job-name=gatk_metrics
#SBATCH --partition=pibu_el8
#SBATCH --account=class-407009-ws-2026
#SBATCH --cpus-per-task=2
#SBATCH --mem=16G
#SBATCH --time=02:00:00
#SBATCH --output=logs/gatk_metrics_%j.out
#SBATCH --error=logs/gatk_metrics_%j.err

set -euo pipefail

module load GATK/4.2.6.1-GCCcore-10.3.0-Java-11
module load R/4.1.0-foss-2021a

PROJECT="/data/users/gercan/CancerGenomics_Practicals"
REF="/data/courses/cancergenomics/VAR_CALLING/bwa_idx/genome.fa"
INPUT="$PROJECT/results/markduplicates"
OUTPUT="$PROJECT/results/gatk_metrics"

mkdir -p "$OUTPUT"

for sample in normal tumor; do

    BAM="$INPUT/${sample}_marked.bam"

    if [[ ! -s "$BAM" ]]; then
        echo "ERROR: Missing BAM: $BAM" >&2
        exit 1
    fi

    echo "Collecting metrics for $sample"

    gatk --java-options "-Xmx12g" \
        CollectMultipleMetrics \
        -I "$BAM" \
        -O "$OUTPUT/${sample}" \
        -R "$REF" \
        --PROGRAM CollectAlignmentSummaryMetrics \
        --PROGRAM CollectInsertSizeMetrics

    echo "$sample metrics completed"

done

echo "All GATK metrics completed."
