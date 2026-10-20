#!/usr/bin/env python3
import gzip
import csv
from pathlib import Path

project = Path("/data/users/gercan/CancerGenomics_Practicals")
input_vcf = project / "results/annotation/vep_annotated.vcf"
clinvar_vcf = Path(
    "/data/courses/cancergenomics/VAR_CALLING/"
    "resources/clinvar/clinvar.vcf.gz"
)
output_dir = project / "results/annotation"
output_dir.mkdir(parents=True, exist_ok=True)

variants = {}
headers = []

with input_vcf.open() as handle:
    for line in handle:
        if line.startswith("#"):
            headers.append(line)
            continue

        fields = line.rstrip("\n").split("\t")
        chrom = fields[0].removeprefix("chr") if hasattr(
            str, "removeprefix"
        ) else fields[0].replace("chr", "", 1)
        for alt in fields[4].split(","):
            key = (chrom, fields[1], fields[3], alt)
            variants[key] = {
                "fields": fields,
                "clinvar_id": ".",
                "clnsig": ".",
                "clndn": "."
            }

def parse_info(info):
    values = {}
    for item in info.split(";"):
        if "=" in item:
            key, value = item.split("=", 1)
            values[key] = value
    return values

matched = set()

with gzip.open(clinvar_vcf, "rt") as handle:
    for line in handle:
        if line.startswith("#"):
            continue

        fields = line.rstrip("\n").split("\t")
        chrom, pos, record_id, ref, alt_field = (
            fields[0], fields[1], fields[2], fields[3], fields[4]
        )

        info = parse_info(fields[7])

        for alt in alt_field.split(","):
            key = (chrom, pos, ref, alt)

            if key in variants:
                variants[key]["clinvar_id"] = record_id
                variants[key]["clnsig"] = info.get("CLNSIG", ".")
                variants[key]["clndn"] = info.get("CLNDN", ".")
                matched.add(key)

output = output_dir / "clinvar_annotation.tsv"

with output.open("w", newline="") as handle:
    writer = csv.writer(handle, delimiter="\t")
    writer.writerow([
        "CHROM", "POS", "REF", "ALT",
        "ClinVar_ID", "CLNSIG", "CLNDN"
    ])

    for key, record in variants.items():
        chrom, pos, ref, alt = key
        writer.writerow([
            chrom, pos, ref, alt,
            record["clinvar_id"],
            record["clnsig"],
            record["clndn"]
        ])

print("Input variants:", len(variants))
print("Matched ClinVar alleles:", len(matched))
print("Unmatched variants:", len(variants) - len(matched))
print("Output:", output)
