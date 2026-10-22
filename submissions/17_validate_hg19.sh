#!/bin/bash
#SBATCH --job-name=validate_hg19
#SBATCH --partition=pibu_el8
#SBATCH --account=class-407009-ws-2026
#SBATCH --cpus-per-task=1
#SBATCH --mem=4G
#SBATCH --time=00:30:00
#SBATCH --output=logs/validate_hg19_%j.out
#SBATCH --error=logs/validate_hg19_%j.err

set -euo pipefail

module load SAMtools/1.13-GCC-10.3.0

PROJECT="/data/users/gercan/CancerGenomics_Practicals"

python3 "$PROJECT/scripts/09_validate_hg19.py" \
    > "$PROJECT/results/mutational_signatures/reference_validation.txt"
