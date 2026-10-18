#!/bin/bash
#SBATCH --job-name=bwa_alignment
#SBATCH --partition=pibu_el8
#SBATCH --account=class-407009-ws-2026
#SBATCH --cpus-per-task=8
#SBATCH --mem=64G
#SBATCH --time=06:00:00
#SBATCH --output=logs/bwa_alignment_%j.out
#SBATCH --error=logs/bwa_alignment_%j.err

set -euo pipefail

module load BWA-MEM2/2.2.1-GCC-10.3.0
module load SAMtools/1.13-GCC-10.3.0

PROJECT=/data/users/gercan/CancerGenomics_Practicals
REF=/data/courses/cancergenomics/VAR_CALLING/bwa_idx/genome.fa
FASTQ="$PROJECT/results/fastp"
OUTPUT="$PROJECT/results/alignment"

mkdir -p "$OUTPUT"

for sample in normal tumor
do
    echo "Starting alignment: $sample"

    bwa-mem2 mem \
        -t 8 \
        -R "@RG\tID:${sample}\tSM:${sample}\tPL:ILLUMINA\tLB:${sample}_lib" \
        "$REF" \
        "$FASTQ/${sample}.trimmed.R1.fq.gz" \
        "$FASTQ/${sample}.trimmed.R2.fq.gz" \
    | samtools view \
        -@ 4 \
        -b \
        -o "$OUTPUT/${sample}_aligned.bam" -

    echo "Alignment completed: $sample"
done

echo "All alignments completed."
