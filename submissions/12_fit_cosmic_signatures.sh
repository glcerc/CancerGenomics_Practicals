#!/bin/bash
#SBATCH --job-name=cosmic_fitting
#SBATCH --partition=pibu_el8
#SBATCH --account=class-407009-ws-2026
#SBATCH --cpus-per-task=2
#SBATCH --mem=8G
#SBATCH --time=01:00:00
#SBATCH --output=logs/cosmic_fitting_%j.out
#SBATCH --error=logs/cosmic_fitting_%j.err

set -euo pipefail

module load R/4.3.2-foss-2021a

export R_LIBS_USER="/data/users/gercan/R/4.3"

Rscript /data/users/gercan/CancerGenomics_Practicals/scripts/12_fit_cosmic_signatures.R
