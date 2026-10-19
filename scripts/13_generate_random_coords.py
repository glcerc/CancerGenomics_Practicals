#!/usr/bin/env python3
import bisect
import csv
import random
import subprocess
from pathlib import Path

PROJECT = Path("/data/users/gercan/CancerGenomics_Practicals")
GTF = Path(
    "/data/courses/cancergenomics/check_and_delete/"
    "Transcriptomics/Data/GENCODE/GENCODE_hg19_chr12.gtf"
)
REFERENCE = PROJECT / "references/hg19.fa"
OUT = PROJECT / "results/mutational_signatures/simulation"
OUT.mkdir(parents=True, exist_ok=True)

rng = random.Random(20261019)

# GTF is 1-based inclusive; BED is 0-based half-open.
intervals = []
with GTF.open() as handle:
    for line in handle:
        if line.startswith("#"):
            continue
        parts = line.rstrip("\n").split("\t")
        if len(parts) < 5 or parts[0] != "chr12" or parts[2] != "exon":
            continue
        start = int(parts[3]) - 1
        end = int(parts[4])
        if end > start:
            intervals.append((start, end))

if not intervals:
    raise RuntimeError("No chr12 exons found")

intervals.sort()
merged = []
for start, end in intervals:
    if merged and start <= merged[-1][1]:
        merged[-1][1] = max(merged[-1][1], end)
    else:
        merged.append([start, end])

with (OUT / "hg19_chr12_exons.bed").open("w") as handle:
    for start, end in merged:
        handle.write("chr12\t{}\t{}\n".format(start, end))

# Fetch chr12 once instead of launching samtools per position.
proc = subprocess.run(
    ["samtools", "faidx", str(REFERENCE), "chr12"],
    check=True,
    stdout=subprocess.PIPE,
    universal_newlines=True
)
sequence = "".join(
    line.strip() for line in proc.stdout.splitlines()
    if not line.startswith(">")
).upper()

lengths = [end - start for start, end in merged]
cumulative = []
total = 0
for length in lengths:
    total += length
    cumulative.append(total)

bases = set("ACGT")
positions = set()
target = 60000
attempts = 0

while len(positions) < target:
    attempts += 1
    if attempts > target * 100:
        raise RuntimeError("Could not generate enough valid positions")
    offset = rng.randrange(total)
    index = bisect.bisect_right(cumulative, offset)
    previous = cumulative[index - 1] if index else 0
    pos0 = merged[index][0] + offset - previous

    if pos0 < 1 or pos0 + 1 >= len(sequence):
        continue
    context = sequence[pos0 - 1:pos0 + 2]
    if len(context) == 3 and set(context) <= bases:
        positions.add(pos0)

with (OUT / "random_positions.tsv").open("w", newline="") as handle:
    writer = csv.writer(handle, delimiter="\t")
    writer.writerow(["chrom", "pos", "ref", "trinucleotide"])
    for pos0 in sorted(positions):
        writer.writerow([
            "chr12", pos0 + 1, sequence[pos0],
            sequence[pos0 - 1:pos0 + 2]
        ])

print("Raw exon entries:", len(intervals))
print("Merged exon intervals:", len(merged))
print("Unique candidate positions:", len(positions))
print("GRCh37 chr12 reference length:", len(sequence))
