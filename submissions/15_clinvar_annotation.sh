#!/bin/bash
#SBATCH --job-name=clinvar_annotation
#SBATCH --partition=pibu_el8
#SBATCH --account=class-407009-ws-2026
#SBATCH --cpus-per-task=1
#SBATCH --mem=4G
#SBATCH --time=00:45:00
#SBATCH --output=logs/clinvar_%j.out
#SBATCH --error=logs/clinvar_%j.err

set -euo pipefail

PROJECT="/data/users/gercan/CancerGenomics_Practicals"

python3 "$PROJECT/scripts/16_annotate_clinvar.py"

echo "ClinVar allele matching completed."
