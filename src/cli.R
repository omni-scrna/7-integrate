#!/usr/bin/env Rscript
# Argument parser for omnibenchmark integrate modules.

suppressPackageStartupMessages(library(optparse))

build_harmony_parser <- function() {
  option_list <- list(
    make_option("--output_dir", type = "character",
                help = "Output directory for results"),
    make_option("--name", type = "character",
                help = "Module name/identifier"),
    make_option("--pcas.tsv", type = "character",
                help = "TSV of uncorrected PCA embeddings (cell_id + PC columns)"),
    make_option("--rawdata.h5ad", type = "character",
                help = "AnnData HDF5 file; obs is read for batch labels"),
    make_option("--batch_variable", type = "character",
                help = "Column name in obs to use as batch variable"),
    make_option("--theta", type = "double",
                help = "Harmony diversity penalty (higher = more correction)")
  )
  OptionParser(
    option_list = option_list,
    description = "OmniBenchmark integration module (harmony)"
  )
}

parse_harmony_args <- function() {
  parser <- build_harmony_parser()
  raw <- parse_args(parser)

  args <- list(
    output_dir     = raw$output_dir,
    name           = raw$name,
    pcas_tsv       = raw[["pcas.tsv"]],
    rawdata_h5ad   = raw[["rawdata.h5ad"]],
    batch_variable = raw$batch_variable,
    theta          = raw$theta
  )

  required <- names(args)
  missing <- required[vapply(args[required], function(v) is.null(v) || is.na(v),
                             logical(1))]
  if (length(missing) > 0) {
    stop("Missing required argument(s): ", paste(missing, collapse = ", "))
  }

  args
}
