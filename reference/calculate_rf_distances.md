# Compute Robinson-Foulds Distances between Maximum-Likelihood Trees

Compute Robinson-Foulds Distances between Maximum-Likelihood Trees

## Usage

``` r
calculate_rf_distances(
  raxml_bin_path,
  ml_trees_file,
  output_dir = dirname(ml_trees_file),
  prefix = "cactus_RF"
)
```

## Arguments

- raxml_bin_path:

  Character. System RAxML-NG path.

- ml_trees_file:

  Character. Path to .raxml.mlTrees file.

- output_dir:

  Character. Directory for outputs. Defaults to ml_trees_file directory.

- prefix:

  Character. Output prefix. Defaults to "cactus_RF".

## Value

Output prefix distance path.
