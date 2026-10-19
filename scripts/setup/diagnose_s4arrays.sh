#!/bin/bash
#SBATCH --job-name=diagnose_s4arrays
#SBATCH --partition=pibu_el8
#SBATCH --account=class-407009-ws-2026
#SBATCH --cpus-per-task=1
#SBATCH --mem=8G
#SBATCH --time=01:00:00
#SBATCH --output=logs/diagnose_s4arrays_%j.out
#SBATCH --error=logs/diagnose_s4arrays_%j.err

set -euo pipefail

module load R/4.3.2-foss-2021a

export R_LIBS_USER="/data/users/gercan/R/4.3"
export MAKEFLAGS="-j1"

Rscript - <<'RSCRIPT'
options(repos = c(CRAN = "https://cloud.r-project.org"))
options(timeout = 1200)

BiocManager::install(
    "S4Arrays",
    lib = Sys.getenv("R_LIBS_USER"),
    ask = FALSE,
    update = FALSE,
    Ncpus = 1
)

if (!requireNamespace("S4Arrays", quietly = TRUE)) {
    stop("S4Arrays installation failed")
}

cat("S4Arrays successfully installed\n")
RSCRIPT
