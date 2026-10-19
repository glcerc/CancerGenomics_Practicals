#!/usr/bin/env python3

import glob
import os
import subprocess

PROJECT = "/data/users/gercan/CancerGenomics_Practicals"
REFERENCE = os.path.join(PROJECT, "references/hg19.fa")
VCF_DIR = os.path.join(
    PROJECT, "course_materials/Exercises/MUT_SIGNATURES"
)

for vcf in sorted(glob.glob(os.path.join(VCF_DIR, "sample_*.vcf"))):
    snvs = 0
    matched = 0
    mismatched = 0
    indels = 0
    examples = []

    with open(vcf) as handle:
        for line in handle:
            if line.startswith("#"):
                continue

            fields = line.strip().split()
            chrom, pos, ref, alt = (
                fields[0], int(fields[1]), fields[3], fields[4]
            )

            if len(ref) != 1 or len(alt) != 1 or "," in alt:
                indels += 1
                continue

            snvs += 1

            region = "{}:{}-{}".format(chrom, pos, pos)

            result = subprocess.run(
                ["samtools", "faidx", REFERENCE, region],
                stdout=subprocess.PIPE,
                stderr=subprocess.PIPE,
                universal_newlines=True,
                check=True,
            )

            sequence = "".join(
                line.strip()
                for line in result.stdout.splitlines()
                if not line.startswith(">")
            ).upper()

            if sequence == ref.upper():
                matched += 1
            else:
                mismatched += 1
                if len(examples) < 3:
                    examples.append(
                        "{}:{} {} != {}".format(
                            chrom, pos, ref, sequence
                        )
                    )

    print(
        "{}: SNVs={}, matched={}, mismatched={}, indels/other={}".format(
            os.path.basename(vcf),
            snvs, matched, mismatched, indels
        )
    )

    for example in examples:
        print("  MISMATCH:", example)
