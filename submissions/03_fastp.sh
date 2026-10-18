#!/bin/bash
#SBATCH --job-name=fastp_cg
#SBATCH --partition=pibu_el8
#SBATCH --account=class-407009-ws-2026
#SBATCH --cpus-per-task=4
#SBATCH --mem=8G
#SBATCH --time=02:00:00
#SBATCH --output=logs/fastp_%j.out
#SBATCH --error=logs/fastp_%j.err

set -euo pipefail

module load fastp/0.23.4-GCC-10.3.0

INPUT=/data/courses/cancergenomics/VAR_CALLING/fastq
PROJECT=/data/users/gercan/CancerGenomics_Practicals
OUTPUT=$PROJECT/results/fastp

mkdir -p "$OUTPUT"

for sample in normal tumor
do
    echo "Processing $sample"

    fastp \
        --in1 "$INPUT/$sample.R1.fq.gz" \
        --in2 "$INPUT/$sample.R2.fq.gz" \
        --out1 "$OUTPUT/$sample.trimmed.R1.fq.gz" \
        --out2 "$OUTPUT/$sample.trimmed.R2.fq.gz" \
        --html "$OUTPUT/$sample.fastp.html" \
        --json "$OUTPUT/$sample.fastp.json" \
        --thread 4

    echo "$sample completed."
done

echo "All FastP analyses completed."
