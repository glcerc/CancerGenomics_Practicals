# Exercise 01 — FastQC

## Input data
Paired-end normal and tumor FASTQ files.

## Tool
FastQC 0.11.9

## Results
All four FASTQ files were processed successfully.

Each sample read file had:
- 9 PASS modules
- 2 WARN modules
- 0 FAIL modules

## Warnings
1. Per sequence GC content:
   The observed GC distribution deviates from the
   expected distribution. This may reflect sample
   preparation or target-region characteristics.

2. Sequence Length Distribution:
   The sequence lengths differ from FastQC's
   expected distribution.

## Interpretation
The four samples passed the per-base quality
and adapter content checks.

The reported warnings do not automatically
indicate that the sequencing data are unusable.
