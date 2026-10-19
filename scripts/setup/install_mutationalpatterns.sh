#!/bin/bash
#SBATCH --job-name=install_mutpat
#SBATCH --partition=pibu_el8
#SBATCH --account=class-407009-ws-2026
#SBATCH --cpus-per-task=2
#SBATCH --mem=12G
#SBATCH --time=03:00:00
#SBATCH --output=logs/install_mutpat_%j.out
#SBATCH --error=logs/install_mutpat_%j.err

set -euo pipefail

module load R/4.3.2-foss-2021a

export R_LIBS_USER="/data/users/gercan/R/4.3"

Rscript /data/users/gercan/CancerGenomics_Practicals/scripts/setup/install_mutationalpatterns.R
