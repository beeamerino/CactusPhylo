# Run Complete Alignment Pipeline

Run Complete Alignment Pipeline

## Usage

``` r
run_alignment_pipeline(
  input_folder,
  output_dir,
  fasta_pattern = "\\.fasta$",
  mask_alignment_regions = TRUE,
  min_non_gap_fraction = 0.3,
  max_missing_fraction = 0.3,
  mafft_exec = "mafft",
  mafft_opts = "--auto"
)
```

## Arguments

- input_folder:

  Character. Folder of raw FASTAs.

- output_dir:

  Character. Directory to save all alignment outputs (will create
  alignments, tables, and logs subdirectories).

- fasta_pattern:

  Character. Pattern to match fasta files.

- mask_alignment_regions:

  Logical. Should DECIPHER masking be applied?

- min_non_gap_fraction:

  Numeric. Minimum fractional non-gap width.

- max_missing_fraction:

  Numeric. Maximum allowed missing states.

- mafft_exec:

  Character. Path to MAFFT.

- mafft_opts:

  Character. Options for MAFFT.

## Value

A data frame containing processing and masking metrics for each marker.
