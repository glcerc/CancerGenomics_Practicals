library(MutationalPatterns)

project <- "/data/users/gercan/CancerGenomics_Practicals"
out <- file.path(
    project, "results/mutational_signatures/simulation"
)

matrix_file <- file.path(out, "simulation_sbs96_matrix.tsv")
truth_file <- file.path(out, "simulation_truth.tsv")

x <- as.matrix(read.delim(
    matrix_file,
    row.names = 1,
    check.names = FALSE
))
storage.mode(x) <- "numeric"

reference_file <- system.file(
    "extdata/signatures/snv_COSMIC_v3.2_reference_GRCh37.txt",
    package = "MutationalPatterns",
    mustWork = TRUE
)
reference <- read.delim(
    reference_file,
    check.names = FALSE,
    stringsAsFactors = FALSE
)

labels <- paste0(
    substr(reference$Subtype, 1, 1),
    "[", reference$Type, "]",
    substr(reference$Subtype, 3, 3)
)

stopifnot(
    nrow(x) == 96,
    setequal(rownames(x), labels),
    all(c("SBS1", "SBS7c") %in% names(reference))
)

signatures <- as.matrix(
    reference[, c("SBS1", "SBS7c")]
)
storage.mode(signatures) <- "numeric"
rownames(signatures) <- labels
x <- x[labels, , drop = FALSE]

fit <- fit_to_signatures(x, signatures)
exposures <- fit$contribution
relative <- sweep(
    exposures, 2, colSums(exposures), "/"
)

truth <- read.delim(truth_file, check.names = FALSE)
stopifnot(setequal(truth$sample, colnames(x)))

truth <- truth[match(colnames(x), truth$sample), ]

results <- data.frame(
    sample = colnames(x),
    n_variants = colSums(x),
    target_SBS1 = truth$target_SBS1,
    generated_SBS1 = truth$generated_SBS1 / truth$n_variants,
    inferred_SBS1 = as.numeric(relative["SBS1", ]),
    target_SBS7c = truth$target_SBS7c,
    generated_SBS7c = truth$generated_SBS7c / truth$n_variants,
    inferred_SBS7c = as.numeric(relative["SBS7c", ])
)

results$absolute_error_SBS1 <- abs(
    results$inferred_SBS1 - results$generated_SBS1
)
results$absolute_error_SBS7c <- abs(
    results$inferred_SBS7c - results$generated_SBS7c
)

write.table(
    results,
    file = file.path(out, "simulation_comparison.tsv"),
    sep = "\t",
    row.names = FALSE,
    quote = FALSE
)

print(results)
