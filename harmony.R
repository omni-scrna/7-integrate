#!/usr/bin/env Rscript
# Harmony batch correction module for omnibenchmark.
#
# Reads uncorrected PCA embeddings (pcas.tsv) and batch labels from the obs
# group of rawdata.h5ad (without loading the count matrix), runs Harmony,
# and writes corrected embeddings in the same TSV layout as the input.

suppressPackageStartupMessages({
  library(harmony)
  library(rhdf5)
  library(data.table)
  library(magrittr)
  library(yaml)
})

script_dir <- (function() {
  cargs <- commandArgs(trailingOnly = FALSE)
  m <- grep("^--file=", cargs)
  if (length(m) > 0) dirname(sub("^--file=", "", cargs[[m]])) else getwd()
})()
source(file.path(script_dir, "src", "cli.R"))


main <- function() {
  args <- parse_harmony_args()
  cat(sprintf("Full command: %s\n", paste(commandArgs(trailingOnly = FALSE), collapse = " ")))
  for (k in names(args)) cat(sprintf("  %s: %s\n", k, args[[k]]))

  dir.create(args$output_dir, showWarnings = FALSE, recursive = TRUE)
  out <- file.path(args$output_dir, paste0(args$name, "_corrected.tsv"))

  # read batch variable from yaml
  batch_variable <- read_yaml(args$batch_info)$batch_variable

  # get pca embedding (needed in both branches)
  pca_df  <- fread(args$pcas_tsv)
  pc_cols <- colnames(pca_df)[grep('PC', colnames(pca_df))]

  # pass-through: write uncorrected PCA with hmny* column names and exit
  if (is.null(batch_variable)) {
    cat("  no batch variable: writing uncorrected PCA as pass-through\n")
    passthrough <- copy(pca_df[, c("cell_id", pc_cols), with = FALSE])
    setnames(passthrough, pc_cols, paste0("hmny", seq_along(pc_cols)))
    fwrite(passthrough, out, sep = "\t", quote = FALSE, row.names = FALSE)
    cat(sprintf("  wrote: %s\n", out))
    return(invisible(NULL))
  }

  embedding <- as.matrix(pca_df[, ..pc_cols]) # cells x PCs
  rownames(embedding) <- pca_df$cell_id
  cat(sprintf("  embedding (cells x PCs): %d x %d\n", nrow(embedding), ncol(embedding)))

  # get cell ids and batch values from obs in h5ad without reading X
  cell_ids   <- h5read(args$rawdata_h5ad, "obs/_index") %>% as.character()
  batch_vals <- h5read(args$rawdata_h5ad, paste0("obs/", batch_variable)) %>%
    as.character()
  meta_dt    <- data.table(cell_id = cell_ids, batch = batch_vals)

  # subset obs to the post-filter cells present in the pca tsv
  meta_dt_filt <- meta_dt %>%
    .[cell_id %chin% pca_df$cell_id] %>%
    data.table::setkey('cell_id')
  # make sure batch values are in correct order
  meta_dt_filt <- meta_dt_filt[pca_df$cell_id]

  cat(sprintf("  batch variable '%s': %d levels (%s)\n",
    batch_variable, length(unique(meta_dt_filt$batch)),
    paste(unique(meta_dt_filt$batch), collapse = ", ")))

  corrected <- RunHarmony(
    data_mat   = embedding,
    meta_data  = data.frame(meta_dt_filt),
    vars_use   = "batch",
    theta      = args$theta,
    verbose    = TRUE
  )

  colnames(corrected) <- paste0("hmny", seq_len(ncol(corrected)))
  fwrite(data.table(cell_id = rownames(corrected), corrected), out, sep = "\t",
    quote = FALSE, row.names = FALSE)
  cat(sprintf("  wrote: %s\n", out))
}

if (sys.nframe() == 0L) {
  main()
}
