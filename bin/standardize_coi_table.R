#!/usr/bin/env Rscript

# Reduce a COI estimate table to (coi_method, specimen_name, coi) so results
# from different COI methods can be concatenated into one table.

suppressMessages(library(optparse))
suppressMessages(library(dplyr))
suppressMessages(library(readr))

opts <- list(
    make_option(
        c("-f", "--table"),
        help = "Input COI TSV with specimen_name and coi columns",
        type = "character"
    ),
    make_option(
        c("--method"),
        help = "COI method label to record in the coi_method column",
        type = "character"
    ),
    make_option(
        c("-o", "--output"),
        help = "Output TSV. Default: %default",
        type = "character",
        default = "coi_table.tsv"
    )
)

parser <- OptionParser(option_list = opts)
args <- parse_args(parser)

if (is.null(args$table) || !file.exists(args$table)) {
    stop(paste(args$table, "does not exist"), call. = FALSE)
}
if (is.null(args$method) || !nzchar(args$method)) {
    stop("Missing required argument: --method", call. = FALSE)
}

tbl <- read_tsv(args$table, show_col_types = FALSE, guess_max = 10000)

missing <- setdiff(c("specimen_name", "coi"), colnames(tbl))
if (length(missing) > 0) {
    stop(
        sprintf("%s is missing required columns: %s", args$table, paste(missing, collapse = ", ")),
        call. = FALSE
    )
}

tbl %>%
    transmute(coi_method = args$method, specimen_name, coi) %>%
    write_tsv(args$output)
