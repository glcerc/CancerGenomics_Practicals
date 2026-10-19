#!/bin/bash
#SBATCH --job-name=install_vep
#SBATCH --partition=pibu_el8
#SBATCH --account=class-407009-ws-2026
#SBATCH --cpus-per-task=2
#SBATCH --mem=16G
#SBATCH --time=03:00:00
#SBATCH --output=logs/install_vep_%j.out
#SBATCH --error=logs/install_vep_%j.err

set -euo pipefail

PROJECT="/data/users/gercan/CancerGenomics_Practicals"
MICROMAMBA="$PROJECT/tools/micromamba/bin/micromamba"

export MAMBA_ROOT_PREFIX="$PROJECT/mamba_root"

"$MICROMAMBA" create -y \
    -p "$PROJECT/conda_envs/vep_env" \
    -c conda-forge \
    -c bioconda \
    --strict-channel-priority \
    ensembl-vep

"$PROJECT/conda_envs/vep_env/bin/vep" --help >/dev/null

echo "VEP installation completed successfully."
