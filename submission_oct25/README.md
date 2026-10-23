# Cancer Genomics Practical 1 — Somatic Variant Calling

**University of Bern · Cancer Genomics, Autumn Semester 2026**

## Group members

1. Gülce Berfin Ercan
2. Tushar Singh
3. Ana Wolf Ruiz

## Scope

This submission covers the somatic variant calling practical: read QC, alignment and BAM
pre-processing, BAM QC, somatic variant calling with GATK Mutect2 and filtering of the calls.

**Data:** whole-exome sequencing of the triple-negative breast cancer cell line HCC1395 (tumor) and the
matched normal HCC1395 BL, subset to chromosomes 6 and 17 (GRCh38), provided under
`/data/courses/cancergenomics/VAR_CALLING/`.

## Scripts

| Script | Step | Tool | Main output (`results/`) |
| --- | --- | --- | --- |
| `01_fastqc_normal.sh` | Raw read QC, normal | FastQC 0.11.9 | `fastqc/normal/` |
| `02_fastqc_tumor.sh` | Raw read QC, tumor | FastQC 0.11.9 | `fastqc/tumor/` |
| `03_fastp.sh` | Adapter/quality trimming + QC | fastp 0.23.4 | `fastp/` |
| `04_multiqc.sh` | Aggregate FastQC + fastp reports | MultiQC 1.11 | `multiqc/multiqc_report.html` |
| `05_bwa_alignment.sh` | Align reads (GRCh38, with read groups) | bwa-mem2 2.2.1, samtools | `alignment/<sample>_aligned.bam` |
| `06_sort_index_bam.sh` | Coordinate sort + index | samtools 1.13 | `alignment/<sample>_sorted.bam` |
| `07_mark_duplicates.sh` | Mark PCR/optical duplicates | GATK MarkDuplicates | `alignment/<sample>_marked.bam`, duplicate metrics |
| `08_base_recalibrator.sh` | BQSR model (dbSNP, Mills/1000G indels) | GATK BaseRecalibrator | `alignment/<sample>_recal.table` |
| `09_apply_bqsr.sh` | Apply BQSR | GATK ApplyBQSR | `alignment/<sample>_recal.bam` |
| `10_bam_quality_control.sh` | BAM QC: course BAMs and our own BAMs | samtools flagstat/stats | `bam_qc/` |
| `11_hs_metrics.sh` | Exome capture metrics (course BAMs) | GATK CollectHsMetrics | `bam_qc/<sample>_hs_metrics.txt` |
| `12_mutect2.sh` | Somatic calling, tumor vs matched normal | GATK Mutect2 4.2.6.1 | `variants/somatic.vcf.gz` |
| `13_filter_mutect_calls.sh` | Filter somatic calls | GATK FilterMutectCalls | `variants/somatic.filtered.vcf.gz` |
| `14_extract_pass_variants.sh` | Keep PASS calls + index | bcftools 1.12 | `variants/somatic.filtered.PASS.vcf.gz` |
| `15_filter_reason_summary.sh` | Summarise filter reasons and PASS variant types | bcftools 1.12 | `variants/filter_reasons_*.tsv` |

## Results

### Read QC (01–04)

| Metric | Normal | Tumor |
| --- | ---: | ---: |
| Reads (R1 + R2) | 12,228,064 | 15,913,646 |
| FastQC modules (per file) | 9 PASS, 2 WARN, 0 FAIL | 9 PASS, 2 WARN, 0 FAIL |
| Q30 (fastp) | 92.1% | 91.3% |
| GC content | 47.2% | 48.0% |
| Reads passing fastp filters | 100% | 100% |
| Insert-size peak (fastp, read overlap) | 169 bp | 169 bp |

The two FastQC warnings (per-sequence GC content, sequence length distribution) are expected for exome
capture data and for FASTQs extracted from processed BAM files. fastp removed no reads, consistent with
the reads having been filtered upstream; alignment therefore uses the original FASTQs (as in the course
template), which is equivalent to using the trimmed files. MultiQC recognised all inputs (FastQC: 4
reports, fastp: 2 reports).

### Alignment, BAM pre-processing and BAM QC (05–10)

bwa-mem2 aligned both samples to the full GRCh38 analysis set (195 contigs, pre-built course index) in
8.5 min (peak memory 20.9 GB). Aligning to the whole genome lets reads from paralogous or repetitive
sequence map to their true origin instead of being forced onto chromosomes 6 and 17. Steps 06–09
completed successfully and produced `normal_recal.bam` and `tumor_recal.bam`.

| Metric (samtools flagstat) | Own normal | Course normal | Own tumor | Course tumor |
| --- | ---: | ---: | ---: | ---: |
| Alignment records | 12,249,199 | 12,744,793 | 15,932,084 | 16,674,562 |
| Mapped | 100.00% | 99.42% | 100.00% | 99.45% |
| Properly paired | 98.63% | 98.30% | 98.83% | 98.43% |
| Duplicates | 10.60% | 10.97% | 10.78% | 11.22% |

Our BAMs closely reproduce the course-provided BAMs (pairing and duplication within ~0.5 percentage
points; MarkDuplicates reports 10.61% / 10.80%). Our BAMs are fully mapped, likely because reads were
aligned to the whole genome, whereas the course BAMs use a chr6/chr17 reference on which reads from
other chromosomes remain unmapped. The course BAMs contain ~4–5% more records, presumably because they were
generated from the original read set rather than from the extracted FASTQs. As instructed in the course,
downstream variant calling (12–15) uses the course-provided recalibrated BAMs.

### Capture metrics of the course BAMs (11)

| Metric (CollectHsMetrics) | Normal | Tumor |
| --- | ---: | ---: |
| Fold enrichment | 22.1 | 22.8 |
| Usable bases on target | 44.3% | 46.1% |
| Mean target coverage | 84.3× | 114.9× |
| Target bases ≥30× | 82.7% | 87.3% |

Capture metrics match the values expected in the course (fold enrichment ~22, ~45% of usable bases on
target, de-duplicated target coverage ~84× / ~114×); 83–87% of target bases are covered by at least 30
reads, sufficient for somatic variant calling.

### Somatic variant calling (12–15)

Mutect2 was run in tumor–normal mode on the exome target intervals with the gnomAD germline resource and
the 1000 Genomes panel of normals. FilterMutectCalls labelled **467** calls; **133 PASS** (121 SNVs,
10 indels, 2 multi-nucleotide variants), which were extracted and indexed in step 14.

| Filter flag (a call can carry several) | Calls |
| --- | ---: |
| normal_artifact | 211 |
| weak_evidence | 141 |
| strand_bias | 138 |
| panel_of_normals | 76 |
| clustered_events | 63 |
| haplotype | 53 |
| slippage | 46 |
| multiallelic | 31 |
| base_qual | 27 |
| map_qual | 24 |
| germline | 23 |
| fragment | 5 |

The most frequent single reasons were weak_evidence (48 calls: likelihood below threshold, usually low
tumor allele fraction), normal_artifact + strand_bias (26) and panel_of_normals (21). normal_artifact
(alt reads also present in the normal) was the most common flag overall, followed by weak_evidence and
strand_bias (alt reads from one strand only), all typical signatures of technical artifacts or residual
germline variation.

## Failed steps, warnings and alternative handling

### Failed steps

None. All submitted scripts completed successfully.

### Warnings

All warnings were non-critical and did not affect the results:

- **All GATK steps (07, 08, 09, 11, 12, 13):** "GATK v4.2.6.1 support for Java 11 is in beta" and
  `IntelInflater - Zero Bytes Written`. These are standard messages of the cluster's GATK module.
- **08 BaseRecalibrator:** the course dbSNP index file is older than the dbSNP VCF, and the VCF has no
  sequence dictionary (GATK reads it from the index instead).
- **12 Mutect2:** the course BAM index files are older than the BAM files.
- **01–02 FastQC:** "Per sequence GC content" and "Sequence length distribution" (explained in the
  Read QC results above).

The index warnings only concern file timestamps or metadata of course-provided files, which we did not modify.

### Alternative handling

- **Course-provided BAMs for variant calling.** As instructed in the course slides, Mutect2 (12) uses
  the recalibrated BAMs provided by the course. Our own alignment and BQSR scripts (05–09) were run
  to show that the pre-processing works; their results are compared with the course BAMs above.
- **BaseRecalibrator only on chr6 and chr17.** Our reads come only from chromosomes 6 and 17, so
  step 08 uses `-L chr6 -L chr17` instead of scanning the whole genome. ApplyBQSR (09) is still
  applied to all reads.
- **Two reference files.** Alignment and BQSR (05–09) use the course bwa-mem2 reference (full GRCh38);
  Mutect2 and FilterMutectCalls (12–13) use the chr6/chr17 reference that matches the course BAMs.
- **Reservation line.** The course template includes `--reservation`, but the session reservations
  have expired and SLURM rejects jobs that request them. The line is therefore kept commented out
  (`##SBATCH`) in every script.
