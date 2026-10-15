#!/bin/bash
set -euo pipefail

PROJECT="/data/users/gercan/CancerGenomics_Practicals"
BAM="$PROJECT/course_materials/Exercises/IGV/HCC1143.normal.21.19M-20M.bam"
OUT="$PROJECT/results/bam_qc"

mkdir -p "$OUT"

echo "1. Checking BAM header"
samtools view -H "$BAM" > "$OUT/bam_header.txt"

echo "2. Mapping statistics"
samtools flagstat "$BAM" > "$OUT/flagstat.txt"

echo "3. Alignment statistics"
samtools stats "$BAM" > "$OUT/bam_stats.txt"

echo "4. Coverage analysis"
samtools depth "$BAM" > "$OUT/depth.txt"

echo "5. BAM index statistics"
samtools idxstats "$BAM" > "$OUT/idxstats.txt"

echo "Quality control completed."
