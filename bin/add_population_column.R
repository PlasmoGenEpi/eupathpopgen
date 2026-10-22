#!/usr/bin/env Rscript

# Prepend a population column to any TSV table.

suppressMessages(library(optparse))
suppressMessages(library(dplyr))
suppressMessages(library(readr))

opts <- list(
    make_option(
        c("-f", "--table"),
        help = "Input TSV",
        type = "character"
    ),
    make_option(
        c("--population"),
        help = "Population label to prepend",
        type = "character"
    ),
    make_option(
        c("-o", "--output"),
        help = "Output TSV. Default: %default",
        type = "character",
        default = "labeled.tsv"
    )
)

parser <- OptionParser(option_list = opts)
args <- parse_args(parser)

if (is.null(args$table) || !file.exists(args$table)) {
    stop(paste(args$table, "does not exist"), call. = FALSE)
}
if (is.null(args$population) || !nzchar(args$population)) {
    stop("Missing required argument: --population", call. = FALSE)
}

tbl <- read_tsv(args$table, show_col_types = FALSE, guess_max = 10000)

if ("population" %in% colnames(tbl)) {
    tbl <- tbl %>% select(-population)
}

tbl_with_pop <- tbl %>%
    mutate(population = args$population) %>%
    select(population, everything())

write_tsv(tbl_with_pop, args$output)
