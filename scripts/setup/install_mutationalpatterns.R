user_lib <- "/data/users/gercan/R/4.3"

dir.create(user_lib, recursive = TRUE, showWarnings = FALSE)
.libPaths(c(user_lib, .libPaths()))

options(repos = c(CRAN = "https://cloud.r-project.org"))
options(timeout = 1200)

if (!requireNamespace("BiocManager", quietly = TRUE)) {
    install.packages("BiocManager", lib = user_lib, Ncpus = 2)
}

if (!requireNamespace("MutationalPatterns", quietly = TRUE)) {
    BiocManager::install(
        "MutationalPatterns",
        lib = user_lib,
        ask = FALSE,
        update = FALSE,
        Ncpus = 2
    )
}

library(MutationalPatterns)

cat("MutationalPatterns installation successful\n")
cat("Version:", as.character(packageVersion("MutationalPatterns")), "\n")
