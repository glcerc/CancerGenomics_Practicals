#!/usr/bin/env python3
import csv
import re
from html import escape
from pathlib import Path

ROOT = Path("/data/users/gercan/CancerGenomics_Practicals")
OUT = ROOT / "figures"
OUT.mkdir(exist_ok=True)


def bar_chart(filename, title, data, note="", max_value=None):
    if not data:
        raise ValueError("No data for " + filename)

    width = 920
    left = 310
    bar_width = 480
    row_height = 42
    top = 100
    height = top + len(data) * row_height + 100
    maximum = max_value or max(value for _, value in data) * 1.12
    maximum = max(maximum, 1)

    parts = [
        '<svg xmlns="http://www.w3.org/2000/svg" '
        'width="920" height="{}" viewBox="0 0 920 {}">'.format(
            height, height
        ),
        '<rect width="100%" height="100%" fill="white"/>',
        '<text x="35" y="45" font-size="23" font-weight="bold" '
        'font-family="Arial" fill="#172b4d">{}</text>'.format(
            escape(title)
        ),
    ]

    for index, (label, value) in enumerate(data):
        y = top + index * row_height
        length = bar_width * float(value) / maximum

        parts.extend([
            '<text x="{}" y="{}" text-anchor="end" font-size="15" '
            'font-family="Arial" fill="#334155">{}</text>'.format(
                left - 15, y + 20, escape(str(label))
            ),
            '<rect x="{}" y="{}" width="{}" height="26" '
            'rx="4" fill="#2563eb"/>'.format(
                left, y, round(length, 2)
            ),
            '<text x="{}" y="{}" font-size="15" '
            'font-family="Arial" fill="#172b4d">{}</text>'.format(
                left + length + 10, y + 19, value
            ),
        ])

    if note:
        parts.append(
            '<text x="35" y="{}" font-size="13" '
            'font-family="Arial" fill="#64748b">{}</text>'.format(
                height - 28, escape(note)
            )
        )

    parts.append("</svg>")
    (OUT / filename).write_text("\n".join(parts) + "\n")
    print("Created:", filename)


summary = (
    ROOT / "results/annotation/variant_annotation_summary.txt"
).read_text()


def section_counts(start, end):
    block = summary.split(start, 1)[1].split(end, 1)[0]
    counts = []
    for line in block.splitlines():
        match = re.fullmatch(r"([A-Za-z0-9_]+):\s*(\d+)", line.strip())
        if match:
            counts.append((match.group(1), int(match.group(2))))
    return counts


impacts = section_counts(
    "MAXIMUM IMPACT DISTRIBUTION",
    "CONSEQUENCE DISTRIBUTION"
)

bar_chart(
    "vep_impact.svg",
    "VEP Maximum Impact Distribution",
    impacts,
    "133 PASS variants; maximum effect across annotated transcripts"
)

consequences = section_counts(
    "CONSEQUENCE DISTRIBUTION",
    "CLINVAR-MATCHED VARIANTS"
)

bar_chart(
    "vep_consequences.svg",
    "Top 10 VEP Consequence Categories",
    sorted(consequences, key=lambda x: -x[1])[:10],
    "Categories overlap because each variant can affect multiple transcripts"
)

clinvar = ROOT / "results/annotation/clinvar_annotation.tsv"
with clinvar.open() as handle:
    rows = list(csv.DictReader(handle, delimiter="\t"))

categories = [
    ("Pathogenic", 0),
    ("Uncertain_significance", 0),
    ("Likely_benign", 0),
    ("Benign", 0)
]
counts = {name: 0 for name, _ in categories}

for row in rows:
    if row["ClinVar_ID"] != ".":
        label = row["CLNSIG"]
        counts[label] = counts.get(label, 0) + 1

bar_chart(
    "clinvar_classifications.svg",
    "ClinVar Clinical Significance",
    [(name, counts[name]) for name, _ in categories],
    "Exact allele matches only; unmatched variants are not necessarily benign"
)

qc = ROOT / "results/mutational_signatures/cosmic/cosmic_fit_qc.tsv"
with qc.open() as handle:
    fit_rows = list(csv.DictReader(handle, delimiter="\t"))

similarities = [
    (row["sample"], float(row["cosine_similarity"]))
    for row in fit_rows
]

bar_chart(
    "cosmic_fit_similarity.svg",
    "COSMIC SBS96 Fit Cosine Similarity",
    similarities,
    "Values closer to 1 indicate better reconstructed profile agreement",
    max_value=1.0
)

print("All four SVG figures generated successfully.")
