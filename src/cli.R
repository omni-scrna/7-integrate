#!/usr/bin/env Rscript
# Argument parser for omnibenchmark integrate modules.

suppressPackageStartupMessages({
  library(optparse)
  library(yaml)
})

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
    make_option("--properties.info", type = "character",
                help = "YAML file with batch_var, sample_var, labels_var fields"),
    make_option("--theta", type = "double",
                help = "Harmony diversity penalty (higher = more correction)"), 
    make_option("--loadings.tsv", type = "character", default = NULL, 
                help = "Ignored")
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
    output_dir      = raw$output_dir,
    name            = raw$name,
    pcas_tsv        = raw[["pcas.tsv"]],
    rawdata_h5ad    = raw[["rawdata.h5ad"]],
    properties_info = raw[["properties.info"]],
    theta           = raw$theta
  )

  required <- names(args)
  missing <- required[vapply(args[required], function(v) is.null(v) || is.na(v),
                             logical(1))]
  if (length(missing) > 0) {
    stop("Missing required argument(s): ", paste(missing, collapse = ", "))
  }

  props <- yaml::read_yaml(args$properties_info)
  if (is.null(props$batch_var) || props$batch_var == "") {
    stop("batch_var is required in properties.info for integration")
  }
  args$batch_variable <- props$batch_var

  args
}
