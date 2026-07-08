# Preprocess Partitions and Run Alignment Check

Preprocess Partitions and Run Alignment Check

## Usage

``` r
preprocess_partitions(
  phy_matrix,
  part_file,
  raxml_path,
  output_dir = dirname(phy_matrix),
  force_check = FALSE
)
```

## Arguments

- phy_matrix:

  Character. Input PHYLIP file path.

- part_file:

  Character. Input partition mapping file.

- raxml_path:

  Character. Location of the RAxML-NG executable.

- output_dir:

  Character. Folders for validated partitions outputs. Defaults to
  dirname(phy_matrix).

- force_check:

  Logical. Bypass run checks if validation exists.
