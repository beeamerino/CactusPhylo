# Calculate and Burn Branch Supports

Calculate and Burn Branch Supports

## Usage

``` r
map_branch_supports(
  raxml_bin,
  best_tree,
  bootstraps_file,
  metric = "tbe",
  threads = 4,
  output_dir = dirname(best_tree),
  prefix = "cactus_support"
)
```

## Arguments

- raxml_bin:

  Character. System RAxML-NG path.

- best_tree:

  Character. Best tree topology path.

- bootstraps_file:

  Character. Replicates tree file path.

- metric:

  Character. Support type ('tbe' or 'fbp').

- threads:

  Integer. Calculations threads count.

- output_dir:

  Character. Directory to write the support file. Defaults to
  dirname(best_tree).

- prefix:

  Character. Output prefix. Defaults to "cactus_support".

## Value

Character path to the written support tree.
