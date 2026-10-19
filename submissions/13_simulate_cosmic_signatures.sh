#!/bin/bash
#SBATCH --job-name=simulate_cosmic
#SBATCH --partition=pibu_el8
#SBATCH --account=class-407009-ws-2026
#SBATCH --cpus-per-task=2
#SBATCH --mem=8G
#SBATCH --time=01:30:00
#SBATCH --output=logs/simulate_cosmic_%j.out
#SBATCH --error=logs/simulate_cosmic_%j.err

set -euo pipefail

module load SAMtools/1.13-GCC-10.3.0
module load R/4.3.2-foss-2021a

export R_LIBS_USER="/data/users/gercan/R/4.3"

PROJECT="/data/users/gercan/CancerGenomics_Practicals"

python3 "$PROJECT/scripts/13_generate_random_coords.py"
python3 "$PROJECT/scripts/14_apply_cosmic_signatures.py"
Rscript "$PROJECT/scripts/15_evaluate_simulation.R"

echo "COSMIC simulation and evaluation completed."
