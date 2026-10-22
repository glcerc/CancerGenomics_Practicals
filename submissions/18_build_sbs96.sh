#!/bin/bash
#SBATCH --job-name=build_sbs96
#SBATCH --partition=pibu_el8
#SBATCH --account=class-407009-ws-2026
#SBATCH --cpus-per-task=1
#SBATCH --mem=4G
#SBATCH --time=01:00:00
#SBATCH --output=logs/sbs96_%j.out
#SBATCH --error=logs/sbs96_%j.err

set -euo pipefail

module load SAMtools/1.13-GCC-10.3.0

PROJECT="/data/users/gercan/CancerGenomics_Practicals"

python3 "$PROJECT/scripts/10_build_sbs96.py"
