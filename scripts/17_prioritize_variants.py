#!/usr/bin/env python3

import csv
import re
from collections import Counter
from pathlib import Path

PROJECT = Path("/data/users/gercan/CancerGenomics_Practicals")
ANNOTATION = PROJECT / "results/annotation"
VCF = ANNOTATION / "vep_annotated.vcf"
CLINVAR = ANNOTATION / "clinvar_annotation.tsv"

IMPACT_RANK = {
    "HIGH": 4,
    "MODERATE": 3,
    "LOW": 2,
    "MODIFIER": 1
}

CLINVAR_RANK = {
    "Pathogenic": 5,
    "Likely_pathogenic": 4,
    "Uncertain_significance": 3,
    "Conflicting_classifications_of_pathogenicity": 2,
    "Likely_benign": 1,
    "Benign": 0
}


def parse_info(info):
    result = {}
    for entry in info.split(";"):
        if "=" in entry:
            key, value = entry.split("=", 1)
            result[key] = value
    return result


def normalize_chrom(chrom):
    return chrom[3:] if chrom.startswith("chr") else chrom


with CLINVAR.open() as handle:
    clinvar_rows = list(csv.DictReader(handle, delimiter="\t"))

clinvar = {
    (normalize_chrom(row["CHROM"]), row["POS"],
     row["REF"], row["ALT"]): row
    for row in clinvar_rows
}

columns = [
    "CHROM", "POS", "REF", "ALT", "SYMBOL",
    "Consequence", "IMPACT", "CANONICAL",
    "HGVSc", "HGVSp", "SIFT", "PolyPhen",
    "ClinVar_ID", "CLNSIG", "CLNDN",
    "Max_IMPACT", "High_Moderate_Transcript",
    "Transcript_Count"
]

rows = []
impact_counts = Counter()
consequence_counts = Counter()
matched_clinvar = 0

with VCF.open() as handle:
    csq_fields = None

    for line in handle:
        if line.startswith("##INFO=<ID=CSQ"):
            match = re.search(r"Format: ([^\">]+)", line)
            if not match:
                raise RuntimeError("Cannot identify CSQ field order")
            csq_fields = match.group(1).split("|")
            continue

        if line.startswith("#"):
            continue

        if csq_fields is None:
            raise RuntimeError("Missing VEP CSQ header")

        fields = line.rstrip("\n").split("\t")
        chrom, pos, ref = fields[0], fields[1], fields[3]
        alt_alleles = fields[4].split(",")
        info = parse_info(fields[7])

        annotations = []
        for entry in info.get("CSQ", "").split(","):
            if not entry:
                continue
            values = entry.split("|")
            annotation = dict(zip(csq_fields, values))
            annotations.append(annotation)

        for alt in alt_alleles:
            # VEP Allele can differ for complex indels.
            # Prefer exact allele matching for SNVs; for other
            # variants, retain all annotations rather than invent
            # an allele-specific assignment.
            if len(ref) == 1 and len(alt) == 1:
                selected = [
                    a for a in annotations
                    if a.get("Allele") == alt
                ]
            else:
                selected = annotations if len(alt_alleles) == 1 else []

            if not selected:
                selected = [{}]

            max_impact = max(
                (a.get("IMPACT", "") for a in selected),
                key=lambda value: IMPACT_RANK.get(value, 0)
            )
            has_high_moderate = any(
                a.get("IMPACT") in ("HIGH", "MODERATE")
                for a in selected
            )

            # Prefer the highest-impact canonical transcript,
            # falling back to the highest-impact annotation.
            best = max(
                selected,
                key=lambda a: (
                    IMPACT_RANK.get(a.get("IMPACT", ""), 0),
                    a.get("CANONICAL", "") == "YES",
                    bool(a.get("SYMBOL", ""))
                )
            )

            key = (normalize_chrom(chrom), pos, ref, alt)
            clinical = clinvar.get(key, {})

            if clinical.get("ClinVar_ID", ".") != ".":
                matched_clinvar += 1

            row = {
                "CHROM": chrom,
                "POS": pos,
                "REF": ref,
                "ALT": alt,
                "SYMBOL": best.get("SYMBOL", ""),
                "Consequence": best.get("Consequence", ""),
                "IMPACT": best.get("IMPACT", ""),
                "CANONICAL": best.get("CANONICAL", ""),
                "HGVSc": best.get("HGVSc", ""),
                "HGVSp": best.get("HGVSp", ""),
                "SIFT": best.get("SIFT", ""),
                "PolyPhen": best.get("PolyPhen", ""),
                "ClinVar_ID": clinical.get("ClinVar_ID", "."),
                "CLNSIG": clinical.get("CLNSIG", "."),
                "CLNDN": clinical.get("CLNDN", "."),
                "Max_IMPACT": max_impact,
                "High_Moderate_Transcript": str(has_high_moderate),
                "Transcript_Count": len(selected)
            }

            rows.append(row)
            impact_counts[max_impact or "UNKNOWN"] += 1

            for consequence in set(
                c
                for annotation in selected
                for c in annotation.get("Consequence", "").split("&")
                if c
            ):
                consequence_counts[consequence] += 1


def priority(row):
    return (
        CLINVAR_RANK.get(row["CLNSIG"], -1),
        IMPACT_RANK.get(row["Max_IMPACT"], 0)
    )


rows.sort(key=priority, reverse=True)

def write_table(path, records):
    with path.open("w", newline="") as handle:
        writer = csv.DictWriter(
            handle, fieldnames=columns, delimiter="\t"
        )
        writer.writeheader()
        writer.writerows(records)


write_table(ANNOTATION / "variant_prioritization.tsv", rows)

high_moderate = [
    row for row in rows
    if row["High_Moderate_Transcript"] == "True"
]
write_table(
    ANNOTATION / "high_moderate_variants.tsv",
    high_moderate
)

summary = [
    "VARIANT ANNOTATION AND PRIORITIZATION",
    "=====================================",
    "Total VEP alleles: {}".format(len(rows)),
    "ClinVar matched alleles: {}".format(matched_clinvar),
    "HIGH/MODERATE alleles: {}".format(len(high_moderate)),
    "",
    "MAXIMUM IMPACT DISTRIBUTION"
]

for label, count in impact_counts.most_common():
    summary.append("{}: {}".format(label, count))

summary.extend(["", "CONSEQUENCE DISTRIBUTION"])
summary.append(
    "Counts may overlap because a variant can have multiple "
    "transcript consequences."
)
for label, count in consequence_counts.most_common():
    summary.append("{}: {}".format(label, count))

summary.extend(["", "CLINVAR-MATCHED VARIANTS"])
for row in rows:
    if row["ClinVar_ID"] != ".":
        summary.append(
            "{}:{} {}>{} | {} | {} | {} | {}".format(
                row["CHROM"], row["POS"],
                row["REF"], row["ALT"],
                row["SYMBOL"] or "UNKNOWN_GENE",
                row["Max_IMPACT"] or "UNKNOWN_IMPACT",
                row["CLNSIG"], row["Consequence"]
            )
        )

summary.extend([
    "",
    "NOTES",
    "-----",
    "ClinVar classifications are not proof of somatic driver status.",
    "Unmatched ClinVar variants are not necessarily benign.",
    "Transcript-specific consequences may differ.",
    "Variants are ranked using clinical classification and VEP impact.",
    "The ranking is exploratory, not a validated oncogenicity score."
])

summary_path = ANNOTATION / "variant_annotation_summary.txt"
summary_path.write_text("\n".join(summary) + "\n")

print("\n".join(summary))
print("\nSaved:")
print(ANNOTATION / "variant_prioritization.tsv")
print(ANNOTATION / "high_moderate_variants.tsv")
print(summary_path)
