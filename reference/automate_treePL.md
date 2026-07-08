# Automate treePL bootstrap pipeline

Automate treePL bootstrap pipeline

## Usage

``` r
automate_treePL(
  cfg_file,
  wrapper_sh,
  ml_tree_file,
  bs_trees_file,
  results_dir,
  treePL_out,
  num_bs = NULL
)
```

## Arguments

- cfg_file:

  Character. Configuration file.

- wrapper_sh:

  Character. Wrapper script path.

- ml_tree_file:

  Character. Path to the maximum-likelihood tree.

- bs_trees_file:

  Character. Bootstraps tree path.

- results_dir:

  Character. Results output dir.

- treePL_out:

  Character. Output treePL directory.

- num_bs:

  Integer or NULL. Number of bootstrap trees to use. If NULL, uses all
  available.
