library(MutationalPatterns)

project <- "/data/users/gercan/CancerGenomics_Practicals"
input_file <- file.path(
    project, "results/mutational_signatures/sbs96_matrix.tsv"
)
output_dir <- file.path(
    project, "results/mutational_signatures/cosmic"
)

dir.create(output_dir, recursive = TRUE, showWarnings = FALSE)

# Read the SBS96 mutation count matrix.
mut_df <- read.delim(
    input_file,
    header = TRUE,
    row.names = 1,
    check.names = FALSE
)
mut_matrix <- as.matrix(mut_df)
storage.mode(mut_matrix) <- "numeric"

stopifnot(
    nrow(mut_matrix) == 96,
    ncol(mut_matrix) == 9,
    !anyNA(mut_matrix),
    all(mut_matrix >= 0)
)

cat("Input matrix:", nrow(mut_matrix), "x", ncol(mut_matrix), "\n")
cat("Mutation counts per sample:\n")
print(colSums(mut_matrix))

# Load COSMIC SBS reference signatures.
cosmic_signatures <- get_known_signatures(
    muttype = "snv",
    source = "COSMIC_v3.2",
    sig_type = "reference",
    genome = "GRCh37"
)
cosmic_signatures <- as.matrix(cosmic_signatures)

cat("COSMIC matrix dimensions:", dim(cosmic_signatures), "\n")

# Recover channel labels from the packaged COSMIC v3.2 reference file.
reference_file <- system.file(
    "extdata/signatures/snv_COSMIC_v3.2_reference_GRCh37.txt",
    package = "MutationalPatterns",
    mustWork = TRUE
)

reference_table <- read.delim(
    reference_file,
    header = TRUE,
    check.names = FALSE,
    stringsAsFactors = FALSE
)

# Construct SBS96 labels from COSMIC Type and Subtype columns.
stopifnot(all(c("Type", "Subtype") %in% colnames(reference_table)))

cosmic_labels <- paste0(
    substr(reference_table$Subtype, 1, 1),
    "[",
    reference_table$Type,
    "]",
    substr(reference_table$Subtype, 3, 3)
)

stopifnot(
    length(cosmic_labels) == 96,
    !anyDuplicated(cosmic_labels),
    setequal(cosmic_labels, rownames(mut_matrix))
)

# Verify that the reference file matches the loaded signature matrix.
reference_values <- as.matrix(
    reference_table[, colnames(cosmic_signatures), drop = FALSE]
)
storage.mode(reference_values) <- "numeric"

stopifnot(
    isTRUE(all.equal(
        unname(reference_values),
        unname(cosmic_signatures),
        tolerance = 1e-12
    ))
)

# Assign verified labels without modifying COSMIC signature values.
rownames(cosmic_signatures) <- cosmic_labels

mut_matrix <- mut_matrix[
    rownames(cosmic_signatures), , drop = FALSE
]

stopifnot(identical(
    rownames(mut_matrix),
    rownames(cosmic_signatures)
))

cat("COSMIC SBS96 channels matched successfully.\\n")
cat("Channel labels constructed from Type and Subtype.\\n")

# Fit known COSMIC signatures to the samples.
fit_res <- fit_to_signatures(
    mut_matrix,
    cosmic_signatures
)

contributions <- fit_res$contribution
reconstructed <- fit_res$reconstructed

# Save the fitted signature exposures.
write.table(
    contributions,
    file = file.path(output_dir, "cosmic_contributions.tsv"),
    sep = "\t",
    quote = FALSE,
    col.names = NA
)

# Save reconstructed mutation spectra.
write.table(
    reconstructed,
    file = file.path(output_dir, "cosmic_reconstructed.tsv"),
    sep = "\t",
    quote = FALSE,
    col.names = NA
)

# Save relative signature contributions.
relative <- sweep(
    contributions,
    2,
    pmax(colSums(contributions), 1),
    "/"
)

write.table(
    relative,
    file = file.path(output_dir, "cosmic_relative_contributions.tsv"),
    sep = "\t",
    quote = FALSE,
    col.names = NA
)

# Save sample-level reconstruction quality.
qc <- data.frame(
    sample = colnames(mut_matrix),
    observed_mutations = colSums(mut_matrix),
    reconstructed_mutations = colSums(reconstructed),
    cosine_similarity = vapply(
        seq_len(ncol(mut_matrix)),
        function(i) {
            observed <- mut_matrix[, i]
            predicted <- reconstructed[, i]
            denominator <- sqrt(
                sum(observed^2) * sum(predicted^2)
            )
            if (denominator == 0) return(NA_real_)
            sum(observed * predicted) / denominator
        },
        numeric(1)
    )
)

write.table(
    qc,
    file = file.path(output_dir, "cosmic_fit_qc.tsv"),
    sep = "\t",
    quote = FALSE,
    row.names = FALSE
)

cat("COSMIC signature fitting completed.\n")
cat("Active signatures per sample:\n")
print(colSums(contributions > 0))
cat("Saved results to:", output_dir, "\n")
