#!/usr/bin/env Rscript

# Concatenate per-population summary TSVs deterministically.

suppressMessages(library(optparse))
suppressMessages(library(readr))
suppressMessages(library(dplyr))
suppressMessages(library(tidyr))

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
    ),
    make_option(
        c("--wide-coi-methods"),
        type = "character",
        default = "",
        dest = "wide_coi_methods",
        help = "If two or more COI methods, pivot to wide columns coi_<method>"
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

wide_methods <- character(0)
if (!is.null(args$wide_coi_methods) && nzchar(args$wide_coi_methods)) {
    wide_methods <- strsplit(args$wide_coi_methods, ",", fixed = TRUE)[[1]]
    wide_methods <- trimws(wide_methods)
    wide_methods <- wide_methods[nzchar(wide_methods)]
    wide_methods <- unique(wide_methods)
}

if (length(wide_methods) > 1) {
    missing <- setdiff(c("population", "specimen_name", "coi_method", "coi"), colnames(combined))
    if (length(missing) > 0) {
        stop(
            sprintf("Cannot pivot COI summary; missing columns: %s", paste(missing, collapse = ", ")),
            call. = FALSE
        )
    }

    combined <- combined %>%
        select(population, specimen_name, coi_method, coi) %>%
        filter(coi_method %in% wide_methods) %>%
        arrange(population, specimen_name, coi_method) %>%
        pivot_wider(
            names_from = coi_method,
            values_from = coi,
            names_prefix = "coi_",
            values_fn = function(x) {
                uniq <- unique(x)
                if (length(uniq) > 1) {
                    stop("Conflicting COI values for the same sample and method", call. = FALSE)
                }
                uniq[[1]]
            }
        )

    for (method in wide_methods) {
        col <- paste0("coi_", method)
        if (!col %in% colnames(combined)) {
            combined[[col]] <- NA_real_
        }
    }
    combined <- combined %>%
        select(population, specimen_name, all_of(paste0("coi_", wide_methods))) %>%
        arrange(population, specimen_name)
} else if (length(wide_methods) == 1) {
    missing <- setdiff(c("population", "specimen_name", "coi"), colnames(combined))
    if (length(missing) > 0) {
        stop(
            sprintf("Cannot write COI summary; missing columns: %s", paste(missing, collapse = ", ")),
            call. = FALSE
        )
    }
    combined <- combined %>%
        select(population, specimen_name, coi) %>%
        arrange(population, specimen_name)
} else {
    sort_cols <- intersect(c("population", "coi_method", "specimen_name", "specimen_name_a", "specimen_name_b", "target_name", "seq", "coi"), colnames(combined))
    if (length(sort_cols) > 0) {
        combined <- combined %>% arrange(across(all_of(sort_cols)))
    }
}

write_tsv(combined, args$output)
