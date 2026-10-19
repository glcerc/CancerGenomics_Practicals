#!/usr/bin/env python3

import csv
import os
from collections import OrderedDict
from html import escape

PROJECT = "/data/users/gercan/CancerGenomics_Practicals"
INPUT = os.path.join(
    PROJECT, "results/mutational_signatures/sbs96_matrix.tsv"
)
OUTPUT = os.path.join(
    PROJECT, "results/mutational_signatures/plots"
)

COLORS = {
    "C>A": "#4E79A7",
    "C>G": "#222222",
    "C>T": "#E15759",
    "T>A": "#76B7B2",
    "T>C": "#59A14F",
    "T>G": "#EDC948",
}


def draw_plot(name, channels, values):
    width = 1600
    height = 650
    left = 85
    top = 90
    plot_width = 1430
    plot_height = 430

    maximum = max(values) if values else 0
    scale = plot_height / max(maximum, 1)
    bar_step = plot_width / len(channels)
    elements = []

    elements.append(
        '<svg xmlns="http://www.w3.org/2000/svg" '
        'width="{}" height="{}" viewBox="0 0 {} {}">'.format(
            width, height, width, height
        )
    )
    elements.append('<rect width="100%" height="100%" fill="white"/>')
    elements.append(
        '<text x="85" y="45" font-size="25" font-family="Arial">'
        '{}</text>'.format(escape(name + " - SBS96 mutational spectrum"))
    )

    for index in range(6):
        value = maximum * index / 5.0
        y = top + plot_height - value * scale
        elements.append(
            '<line x1="{}" y1="{:.1f}" x2="{}" y2="{:.1f}" '
            'stroke="#dddddd"/>'.format(
                left, y, left + plot_width, y
            )
        )
        elements.append(
            '<text x="75" y="{:.1f}" text-anchor="end" '
            'font-size="13" font-family="Arial">{:.1f}</text>'.format(
                y + 4, value
            )
        )

    for index, (channel, value) in enumerate(zip(channels, values)):
        substitution = channel[2:5]
        color = COLORS[substitution]
        x = left + index * bar_step
        bar_height = value * scale
        y = top + plot_height - bar_height

        elements.append(
            '<rect x="{:.2f}" y="{:.2f}" width="{:.2f}" '
            'height="{:.2f}" fill="{}"/>'.format(
                x, y, max(bar_step - 1, 1), bar_height, color
            )
        )
        elements.append(
            '<text transform="translate({:.1f},{:.1f}) rotate(65)" '
            'font-size="9" font-family="Arial">{}</text>'.format(
                x + 2, top + plot_height + 12, escape(channel)
            )
        )

    elements.append(
        '<text x="25" y="325" transform="rotate(-90 25 325)" '
        'font-size="17" font-family="Arial">Mutation count</text>'
    )

    for index, (substitution, color) in enumerate(COLORS.items()):
        x = 250 + index * 175
        elements.append(
            '<rect x="{}" y="605" width="18" height="18" '
            'fill="{}"/>'.format(x, color)
        )
        elements.append(
            '<text x="{}" y="619" font-size="16" '
            'font-family="Arial">{}</text>'.format(
                x + 25, substitution.replace(">", "&gt;")
            )
        )

    elements.append("</svg>")

    path = os.path.join(OUTPUT, name + "_sbs96.svg")
    with open(path, "w") as handle:
        handle.write("\n".join(elements))

    print("Saved:", path)


def main():
    os.makedirs(OUTPUT, exist_ok=True)

    with open(INPUT) as handle:
        reader = csv.DictReader(handle, delimiter="\t")
        rows = list(reader)
        samples = [
            name for name in reader.fieldnames
            if name != "MutationType"
        ]

    channels = [row["MutationType"] for row in rows]

    if len(channels) != 96 or len(set(channels)) != 96:
        raise ValueError("Expected 96 unique SBS channels")

    for sample in samples:
        values = [int(row[sample]) for row in rows]
        draw_plot(sample, channels, values)

    combined = [
        sum(int(row[sample]) for sample in samples)
        for row in rows
    ]
    draw_plot("all_samples", channels, combined)


if __name__ == "__main__":
    main()
