#!/bin/bash
#SBATCH --job-name=install_r_deps
#SBATCH --partition=pibu_el8
#SBATCH --account=class-407009-ws-2026
#SBATCH --cpus-per-task=2
#SBATCH --mem=12G
#SBATCH --time=03:00:00
#SBATCH --output=logs/install_r_deps_%j.out
#SBATCH --error=logs/install_r_deps_%j.err

set -euo pipefail

module load R/4.3.2-foss-2021a

export R_LIBS_USER="/data/users/gercan/R/4.3"
export MAKEFLAGS="-j2"

Rscript - <<'RSCRIPT'
user_lib <- Sys.getenv("R_LIBS_USER")
dir.create(user_lib, recursive = TRUE, showWarnings = FALSE)
.libPaths(c(user_lib, .libPaths()))

options(repos = c(CRAN = "https://cloud.r-project.org"))
options(timeout = 1200)

# Install an R 4.3-compatible lattice release.
if (!requireNamespace("lattice", quietly = TRUE)) {
    install.packages(
        "https://cran.r-project.org/src/contrib/Archive/lattice/lattice_0.22-6.tar.gz",
        repos = NULL,
        type = "source",
        lib = user_lib
    )
}
stopifnot(requireNamespace("lattice", quietly = TRUE))

# Install an R 4.3-compatible Matrix release.
if (!requireNamespace("Matrix", quietly = TRUE)) {
    install.packages(
        "https://cran.r-project.org/src/contrib/Archive/Matrix/Matrix_1.6-5.tar.gz",
        repos = NULL,
        type = "source",
        lib = user_lib
    )
}
stopifnot(requireNamespace("Matrix", quietly = TRUE))

cat("lattice:", as.character(packageVersion("lattice")), "\n")
cat("Matrix:", as.character(packageVersion("Matrix")), "\n")

# Install the remaining Bioconductor dependencies.
BiocManager::install(
    "MutationalPatterns",
    lib = user_lib,
    ask = FALSE,
    update = FALSE,
    Ncpus = 1
)

stopifnot(requireNamespace("MutationalPatterns", quietly = TRUE))

cat("MutationalPatterns installation successful\n")
cat("Version:", as.character(packageVersion("MutationalPatterns")), "\n")
RSCRIPT
