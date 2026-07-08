# Run Ingroup Marker Screening Pipeline

Run Ingroup Marker Screening Pipeline

## Usage

``` r
run_marker_screening(
  fasta_folder,
  out_base,
  min_cols_to_evaluate = 50L,
  min_aln_len_to_retain = 200L,
  min_nseq_to_retain = 100L,
  max_marker_missing = 0.7,
  saturation_flag_cutoff = 0.3,
  saturation_keep_cutoff = 0.5,
  iqr_multiplier = 1.5
)
```

## Arguments

- fasta_folder:

  Character. Directory containing aligned FASTAs.

- out_base:

  Character. Base directory for output files.

- min_cols_to_evaluate:

  Integer. Minimum columns to evaluate.

- min_aln_len_to_retain:

  Integer. Minimum alignment length to retain.

- min_nseq_to_retain:

  Integer. Minimum sequences to retain.

- max_marker_missing:

  Numeric. Maximum missing fraction for a marker.

- saturation_flag_cutoff:

  Numeric.

- saturation_keep_cutoff:

  Numeric. Retention threshold for the saturation slope.

- iqr_multiplier:

  Numeric. Scale factor for IQR outlier bounds detection.

## Value

Summarized table.
