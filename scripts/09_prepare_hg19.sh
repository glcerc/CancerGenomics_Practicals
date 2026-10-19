#!/bin/bash
#SBATCH --job-name=prepare_hg19
#SBATCH --partition=pibu_el8
#SBATCH --account=class-407009-ws-2026
#SBATCH --cpus-per-task=2
#SBATCH --mem=8G
#SBATCH --time=03:00:00
#SBATCH --output=logs/prepare_hg19_%j.out
#SBATCH --error=logs/prepare_hg19_%j.err

set -euo pipefail

module load SAMtools/1.13-GCC-10.3.0

PROJECT="/data/users/gercan/CancerGenomics_Practicals"
REFDIR="$PROJECT/references"

mkdir -p "$REFDIR"

curl -fL --retry 3 \
    "https://hgdownload.soe.ucsc.edu/goldenPath/hg19/bigZips/hg19.fa.gz" \
    -o "$REFDIR/hg19.fa.gz"

gzip -t "$REFDIR/hg19.fa.gz"
gzip -dc "$REFDIR/hg19.fa.gz" > "$REFDIR/hg19.fa"

samtools faidx "$REFDIR/hg19.fa"

echo "Reference preparation completed."
head -n 3 "$REFDIR/hg19.fa.fai"
