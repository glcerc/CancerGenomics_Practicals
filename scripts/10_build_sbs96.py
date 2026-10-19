#!/usr/bin/env python3

import csv
import glob
import os
import subprocess
from collections import Counter

PROJECT = "/data/users/gercan/CancerGenomics_Practicals"
REFERENCE = os.path.join(PROJECT, "references/hg19.fa")
INPUT_DIR = os.path.join(
    PROJECT, "course_materials/Exercises/MUT_SIGNATURES"
)
OUTPUT_DIR = os.path.join(
    PROJECT, "results/mutational_signatures"
)

BASES = "ACGT"
COMPLEMENT = str.maketrans("ACGT", "TGCA")
SUBSTITUTIONS = ["C>A", "C>G", "C>T", "T>A", "T>C", "T>G"]

CHANNELS = [
    "{}[{}]{}".format(left, substitution, right)
    for substitution in SUBSTITUTIONS
    for left in BASES
    for right in BASES
]


def get_context(chrom, pos):
    region = "{}:{}-{}".format(chrom, pos - 1, pos + 1)

    result = subprocess.run(
        ["samtools", "faidx", REFERENCE, region],
        check=True,
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
        universal_newlines=True,
    )

    return "".join(
        line.strip()
        for line in result.stdout.splitlines()
        if not line.startswith(">")
    ).upper()


def get_channel(context, ref, alt):
    if len(context) != 3 or any(base not in BASES for base in context):
        return None

    if context[1] != ref:
        raise ValueError(
            "Reference mismatch: {} != {}".format(context[1], ref)
        )

    if ref in "AG":
        context = context.translate(COMPLEMENT)[::-1]
        ref = ref.translate(COMPLEMENT)
        alt = alt.translate(COMPLEMENT)

    return "{}[{}>{}]{}".format(
        context[0], ref, alt, context[2]
    )


def main():
    os.makedirs(OUTPUT_DIR, exist_ok=True)

    matrix = {}
    qc_rows = []

    for path in sorted(glob.glob(os.path.join(INPUT_DIR, "sample_*.vcf"))):
        sample = os.path.splitext(os.path.basename(path))[0]
        counts = Counter()
        snvs = 0
        excluded = 0
        invalid_context = 0

        with open(path) as handle:
            for line in handle:
                if line.startswith("#"):
                    continue

                fields = line.rstrip("\n").split("\t")
                chrom = fields[0]
                pos = int(fields[1])
                ref = fields[3].upper()
                alt = fields[4].upper()

                if (
                    len(ref) != 1
                    or len(alt) != 1
                    or ref not in BASES
                    or alt not in BASES
                    or ref == alt
                ):
                    excluded += 1
                    continue

                snvs += 1
                context = get_context(chrom, pos)
                channel = get_channel(context, ref, alt)

                if channel is None:
                    invalid_context += 1
                    continue

                counts[channel] += 1

        matrix[sample] = counts

        qc_rows.append({
            "sample": sample,
            "snvs": snvs,
            "assigned_sbs96": sum(counts.values()),
            "excluded_other": excluded,
            "invalid_context": invalid_context,
        })

        print(
            "{}: SNVs={}, assigned={}, excluded={}, invalid_context={}".format(
                sample, snvs, sum(counts.values()),
                excluded, invalid_context
            )
        )

    matrix_path = os.path.join(OUTPUT_DIR, "sbs96_matrix.tsv")

    with open(matrix_path, "w", newline="") as handle:
        writer = csv.writer(handle, delimiter="\t")
        samples = sorted(matrix)
        writer.writerow(["MutationType"] + samples)

        for channel in CHANNELS:
            writer.writerow(
                [channel] + [matrix[sample][channel] for sample in samples]
            )

    qc_path = os.path.join(OUTPUT_DIR, "sbs96_qc.tsv")

    with open(qc_path, "w", newline="") as handle:
        writer = csv.DictWriter(
            handle,
            fieldnames=[
                "sample", "snvs", "assigned_sbs96",
                "excluded_other", "invalid_context"
            ],
            delimiter="\t",
        )
        writer.writeheader()
        writer.writerows(qc_rows)

    print("Saved:", matrix_path)
    print("Saved:", qc_path)


if __name__ == "__main__":
    main()
