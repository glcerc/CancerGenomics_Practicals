#!/usr/bin/env python3
import collections
import csv
import random
from pathlib import Path

PROJECT = Path("/data/users/gercan/CancerGenomics_Practicals")
OUT = PROJECT / "results/mutational_signatures/simulation"
COSMIC = Path(
    "/data/users/gercan/R/4.3/MutationalPatterns/extdata/signatures/"
    "snv_COSMIC_v3.2_reference_GRCh37.txt"
)

COMP = str.maketrans("ACGT", "TGCA")
BASES = "ACGT"


def canonical_context(context):
    if context[1] in "CT":
        return context
    return context.translate(COMP)[::-1]


def channel_label(mutation_type, context):
    return "{}[{}]{}".format(
        context[0], mutation_type, context[2]
    )


profiles = {"SBS1": {}, "SBS7c": {}}
with COSMIC.open() as handle:
    for row in csv.DictReader(handle, delimiter="\t"):
        context = row["Subtype"].upper()
        mutation_type = row["Type"].upper()
        label = channel_label(mutation_type, context)
        for signature in profiles:
            profiles[signature][label] = float(row[signature])

for name, values in profiles.items():
    if len(values) != 96:
        raise RuntimeError("Expected 96 channels for " + name)
    total = sum(values.values())
    profiles[name] = {
        channel: value / total for channel, value in values.items()
    }

# Group valid genomic positions by canonical trinucleotide context.
pools = collections.defaultdict(list)
with (OUT / "random_positions.tsv").open() as handle:
    for row in csv.DictReader(handle, delimiter="\t"):
        context = row["trinucleotide"].upper()
        pools[canonical_context(context)].append(row)

experiments = [
    ("n100_mix70_30", 100, 0.70),
    ("n500_mix70_30", 500, 0.70),
    ("n1000_mix70_30", 1000, 0.70),
    ("n500_mix50_50", 500, 0.50)
]

rng = random.Random(20261020)
channels = sorted(profiles["SBS1"])
summary = []

with (OUT / "simulation_sbs96_matrix.tsv").open("w", newline="") as matrix_handle:
    matrix_writer = csv.writer(matrix_handle, delimiter="\t")
    matrix_writer.writerow(
        ["MutationType"] + [experiment[0] for experiment in experiments]
    )

    all_counts = {}

    for name, n, fraction_sbs1 in experiments:
        # Copy site lists so each VCF uses unique genomic coordinates.
        available = {
            key: list(values) for key, values in pools.items()
        }
        for sites in available.values():
            rng.shuffle(sites)

        counts = collections.Counter()
        truth = collections.Counter()
        records = []

        for _ in range(n):
            signature = (
                "SBS1" if rng.random() < fraction_sbs1 else "SBS7c"
            )
            labels = list(profiles[signature])
            weights = [profiles[signature][label] for label in labels]

            # Sample a channel with an available matching context.
            valid = [
                (label, weight)
                for label, weight in zip(labels, weights)
                if available[label[0] + label[2] + label[-1]]
            ]
            if not valid:
                raise RuntimeError("No compatible positions remain")

            chosen = rng.choices(
                [item[0] for item in valid],
                weights=[item[1] for item in valid],
                k=1
            )[0]

            mutation_type = chosen[2:5]
            canonical_tri = chosen[0] + mutation_type[0] + chosen[-1]
            site = available[canonical_tri].pop()

            reference = site["ref"].upper()
            alt_canonical = mutation_type[-1]
            alt = (
                alt_canonical if reference in "CT"
                else alt_canonical.translate(COMP)
            )
            if alt == reference:
                raise RuntimeError("Invalid simulated substitution")

            counts[chosen] += 1
            truth[signature] += 1
            records.append((
                "chr12", int(site["pos"]), reference, alt, signature
            ))

        vcf = OUT / (name + ".vcf")
        with vcf.open("w") as handle:
            handle.write("##fileformat=VCFv4.2\n")
            handle.write(
                '##INFO=<ID=SIMSIG,Number=1,Type=String,'
                'Description="Generating COSMIC signature">\n'
            )
            handle.write("#CHROM\tPOS\tID\tREF\tALT\tQUAL\tFILTER\tINFO\n")
            for chrom, pos, ref, alt, signature in sorted(
                records, key=lambda record: record[1]
            ):
                handle.write(
                    "{}\t{}\t.\t{}\t{}\t.\tPASS\tSIMSIG={}\n".format(
                        chrom, pos, ref, alt, signature
                    )
                )

        all_counts[name] = counts
        summary.append([
            name, n, fraction_sbs1, 1 - fraction_sbs1,
            truth["SBS1"], truth["SBS7c"]
        ])
        print(name, "variants:", len(records), "truth:", dict(truth))

    for channel in channels:
        matrix_writer.writerow(
            [channel] + [
                all_counts[name][channel]
                for name, _, _ in experiments
            ]
        )

with (OUT / "simulation_truth.tsv").open("w", newline="") as handle:
    writer = csv.writer(handle, delimiter="\t")
    writer.writerow([
        "sample", "n_variants", "target_SBS1", "target_SBS7c",
        "generated_SBS1", "generated_SBS7c"
    ])
    writer.writerows(summary)

print("Simulation outputs saved to:", OUT)
