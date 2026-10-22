#!/usr/bin/env Rscript

# Concatenate per-population summary TSVs deterministically.

suppressMessages(library(optparse))
suppressMessages(library(readr))
suppressMessages(library(dplyr))

opts <- list(
    make_option(
        c("--files"),
        type = "character",
        help = "Comma-separated list of TSV paths"
    ),
    make_option(
        c("--output"),
        type = "character",
        help = "Output TSV path"
    )
)

parser <- OptionParser(option_list = opts)
args <- parse_args(parser)

if (is.null(args$files) || !nzchar(args$files)) {
    stop("Missing required argument: --files", call. = FALSE)
}
if (is.null(args$output) || !nzchar(args$output)) {
    stop("Missing required argument: --output", call. = FALSE)
}

files <- strsplit(args$files, ",", fixed = TRUE)[[1]]
files <- files[nzchar(files)]
if (length(files) == 0) {
    stop("No input files provided to --files", call. = FALSE)
}

dfs <- lapply(files, function(f) {
    if (!file.exists(f)) {
        stop(sprintf("Input file does not exist: '%s'", f), call. = FALSE)
    }
    read_tsv(f, show_col_types = FALSE, guess_max = 10000)
})

combined <- bind_rows(dfs)

sort_cols <- intersect(c("population", "coi_method", "specimen_name", "specimen_name_a", "specimen_name_b", "target_name", "seq", "coi"), colnames(combined))
if (length(sort_cols) > 0) {
    combined <- combined %>% arrange(across(all_of(sort_cols)))
}

write_tsv(combined, args$output)
