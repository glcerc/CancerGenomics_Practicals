# Cancer Genomics Practical 1 — Somatic Variant Calling

**University of Bern · Cancer Genomics, Autumn Semester 2026 · UBELIX / IBU cluster**

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

## How to run

1. Create a log folder in the directory you submit from: `mkdir -p logs`.
2. Outputs are written to `$PROJECT/results/`. `PROJECT` defaults to
   `/data/users/$USER/CancerGenomics_Practicals`; to use another location, run
   `export PROJECT=/path/to/project` before submitting.
3. Submit the scripts in numerical order, each after its input exists, e.g. `sbatch 01_fastqc_normal.sh`.
4. Course input data are read from `/data/courses/cancergenomics/` (read-only).

All scripts are SLURM batch scripts with the course header (partition `pibu_el8`, account
`class-407009-ws-2026`, job name, memory, time). The course `--reservation` line is kept but commented
out (`##SBATCH`): the session reservations (`class-407009-2026-10-08` / `-10-15`) have expired and SLURM
now rejects jobs that request them ("Requested reservation is invalid").

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
downstream variant calling (12–15) uses the course-provided recalibrated BAMs so that all groups work
with standardised files.

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

## Issues encountered and alternative handling

- **Course-provided BAMs for calling.** Our alignment → BQSR scripts (05–09) were run to validate the
  pre-processing workflow; as instructed in the course, variant calling used the course-provided
  recalibrated BAMs.
- **BaseRecalibrator restricted to chr6/chr17 (`-L chr6 -L chr17`).** The course reads originate from
  chromosomes 6 and 17 only, so the recalibration model was built on these chromosomes to avoid scanning
  the rest of the genome (~40 min for both samples). ApplyBQSR is applied to the whole BAM.
- **Two references.** Alignment/BQSR use the course bwa-mem2 index (`bwa_idx/genome.fa`, full GRCh38);
  Mutect2/FilterMutectCalls use `reference/ref_genome.fa` (chr6 and chr17), matching the course BAMs.
  Chromosome lengths are identical in both.
- **Intermediate files.** Steps 06, 07 and 09 delete the previous BAM only after `samtools quickcheck`
  confirms the new one, to limit disk usage.
- **Warnings (non-critical).** GATK 4.2.6.1 reports that its Java 11 support is "in beta" and logs
  `IntelInflater - Zero Bytes Written` (benign decompression message). BaseRecalibrator (08) warns that the
  course dbSNP index is older than the VCF and that the VCF has no sequence dictionary (taken from the
  index instead). Mutect2 (12) warns that the course BAM index files are older than the BAMs. All concern
  timestamps or metadata of course-provided files, which were not modified; all jobs completed normally.
- **Reservation line.** Kept commented out in every script (see "How to run").
- **Portable paths.** Scripts use `PROJECT="${PROJECT:-/data/users/$USER/CancerGenomics_Practicals}"`
  so any group member can run them without editing.
