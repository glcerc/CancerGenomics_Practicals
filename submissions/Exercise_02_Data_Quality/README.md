# Exercise 02 — BAM Quality Control

## Objective

Evaluate the alignment quality and sequencing coverage
of the HCC1143 normal sample using SAMtools.

## Input Data

HCC1143.normal.21.19M-20M.bam

## Tools

- SAMtools 1.13
- Bash
- AWK

## Results

| Metric | Value |
|---|---|
| QC-passed alignment records | 511,065 |
| QC-failed alignment records | 61,666 |
| QC-passed mapped reads | 99.01% |
| QC-passed properly paired reads | 97.55% |
| QC-passed duplicate rate | 4.78% |
| Covered positions | 997,763 |
| Mean depth (covered positions) | 47.60x |
| Maximum depth | 280x |

## Interpretation

The sequencing data show high alignment and pairing rates
among QC-passed records.

The mean sequencing depth across covered positions is 47.60x.
This provides substantial read support across the analyzed region.

However, mapping statistics alone cannot establish the reliability
of individual variant calls. Base quality, mapping quality, and
variant-level evidence should also be evaluated.

## Reproducibility

Run the quality control script:

bash submissions/Exercise_02_Data_Quality/01_bam_qc.sh
