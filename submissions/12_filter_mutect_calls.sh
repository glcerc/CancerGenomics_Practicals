#!/bin/bash
#SBATCH --job-name=filter_mutect
#SBATCH --partition=pibu_el8
#SBATCH --account=class-407009-ws-2026
#SBATCH --cpus-per-task=2
#SBATCH --mem=12G
#SBATCH --time=01:00:00
#SBATCH --output=logs/filter_mutect_%j.out
#SBATCH --error=logs/filter_mutect_%j.err

set -euo pipefail

module load GATK/4.2.6.1-GCCcore-10.3.0-Java-11

PROJECT="/data/users/gercan/CancerGenomics_Practicals"
BASE="/data/courses/cancergenomics/VAR_CALLING"

REF="$BASE/reference/ref_genome.fa"
INPUT="$PROJECT/results/variants/somatic.vcf.gz"
OUTPUT="$PROJECT/results/variants/somatic.filtered.vcf.gz"

if [[ ! -s "$INPUT" ]]; then
    echo "ERROR: Mutect2 VCF does not exist: $INPUT" >&2
    exit 1
fi

gatk --java-options "-Xmx8g" FilterMutectCalls \
    -R "$REF" \
    -V "$INPUT" \
    -O "$OUTPUT"

echo "FilterMutectCalls completed successfully."
