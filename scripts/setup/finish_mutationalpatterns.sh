#!/bin/bash
#SBATCH --job-name=finish_mutpat
#SBATCH --partition=pibu_el8
#SBATCH --account=class-407009-ws-2026
#SBATCH --cpus-per-task=2
#SBATCH --mem=12G
#SBATCH --time=02:00:00
#SBATCH --output=logs/finish_mutpat_%j.out
#SBATCH --error=logs/finish_mutpat_%j.err

set -euo pipefail

module load R/4.3.2-foss-2021a

export R_LIBS_USER="/data/users/gercan/R/4.3"
export MAKEFLAGS="-j1"

Rscript - <<'RSCRIPT'
user_lib <- Sys.getenv("R_LIBS_USER")
.libPaths(c(user_lib, .libPaths()))
options(repos = c(CRAN = "https://cloud.r-project.org"))

if (!requireNamespace("MASS", quietly = TRUE)) {
    install.packages(
        "https://cran.r-project.org/src/contrib/Archive/MASS/MASS_7.3-60.0.1.tar.gz",
        repos = NULL,
        type = "source",
        lib = user_lib
    )
}
stopifnot(requireNamespace("MASS", quietly = TRUE))
cat("MASS OK\n")

if (!requireNamespace("ggdendro", quietly = TRUE)) {
    install.packages("ggdendro", lib = user_lib)
}
stopifnot(requireNamespace("ggdendro", quietly = TRUE))
cat("ggdendro OK\n")

if (!requireNamespace("MutationalPatterns", quietly = TRUE)) {
    BiocManager::install(
        "MutationalPatterns",
        lib = user_lib,
        ask = FALSE,
        update = FALSE,
        Ncpus = 1
    )
}
stopifnot(requireNamespace("MutationalPatterns", quietly = TRUE))

cat("SUCCESS: MutationalPatterns installed\n")
cat("Version:", as.character(packageVersion("MutationalPatterns")), "\n")
RSCRIPT
