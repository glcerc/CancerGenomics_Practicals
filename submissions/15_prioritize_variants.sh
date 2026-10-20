#!/bin/bash
#SBATCH --job-name=variant_priority
#SBATCH --partition=pibu_el8
#SBATCH --account=class-407009-ws-2026
#SBATCH --cpus-per-task=1
#SBATCH --mem=2G
#SBATCH --time=00:15:00
#SBATCH --output=logs/variant_priority_%j.out
#SBATCH --error=logs/variant_priority_%j.err

set -euo pipefail

PROJECT="/data/users/gercan/CancerGenomics_Practicals"

python3 "$PROJECT/scripts/17_prioritize_variants.py"

echo "Variant prioritization completed."
