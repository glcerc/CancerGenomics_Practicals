#!/bin/bash
#SBATCH --job-name=plot_sbs96
#SBATCH --partition=pibu_el8
#SBATCH --account=class-407009-ws-2026
#SBATCH --cpus-per-task=1
#SBATCH --mem=2G
#SBATCH --time=00:10:00
#SBATCH --output=logs/plot_sbs96_%j.out
#SBATCH --error=logs/plot_sbs96_%j.err

set -euo pipefail

PROJECT="/data/users/gercan/CancerGenomics_Practicals"

python3 "$PROJECT/scripts/11_plot_sbs96.py"
