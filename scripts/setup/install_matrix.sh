#!/bin/bash
#SBATCH --job-name=install_matrix
#SBATCH --partition=pibu_el8
#SBATCH --account=class-407009-ws-2026
#SBATCH --cpus-per-task=2
#SBATCH --mem=8G
#SBATCH --time=01:00:00
#SBATCH --output=logs/install_matrix_%j.out
#SBATCH --error=logs/install_matrix_%j.err

set -euo pipefail

module load R/4.3.2-foss-2021a

export R_LIBS_USER="/data/users/gercan/R/4.3"
export MAKEFLAGS="-j2"

Rscript - <<'RSCRIPT'
dir.create(Sys.getenv("R_LIBS_USER"),
           recursive = TRUE, showWarnings = FALSE)

install.packages(
    "https://cran.r-project.org/src/contrib/Archive/Matrix/Matrix_1.6-5.tar.gz",
    repos = NULL,
    type = "source",
    lib = Sys.getenv("R_LIBS_USER"),
    Ncpus = 2
)

library(Matrix)
cat("Matrix installed successfully\n")
cat("Version:", as.character(packageVersion("Matrix")), "\n")
RSCRIPT
