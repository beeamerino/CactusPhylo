# Compute Temporal Best Maximum-Likelihood Tree Constrained Bootstrap Replicates

Compute Temporal Best Maximum-Likelihood Tree Constrained Bootstrap
Replicates

## Usage

``` r
calculate_temporal_bootstraps(
  raxml_bin_path,
  aln_file,
  part_file,
  best_tree_file,
  bs_trees = 500,
  outgroup = NULL,
  seed = 111,
  threads = 4,
  output_dir = dirname(aln_file),
  prefix = "cactus_temporal"
)
```

## Arguments

- raxml_bin_path:

  Character. System RAxML-NG path.

- aln_file:

  Character. Multiple sequence alignment path.

- part_file:

  Character. Partitions model path.

- best_tree_file:

  Character. Best tree topology path (used as constraint).

- bs_trees:

  Integer. Bootstrap replicates for temporal analysis. Defaults to 500.

- outgroup:

  Character. Outgroup taxon. Defaults to NULL.

- seed:

  Integer. Seed. Defaults to 111.

- threads:

  Integer. Run threads.

- output_dir:

  Character. Directory to write outputs.

- prefix:

  Character. Output prefix. Defaults to "cactus_temporal".

## Value

Output bootstrap trees file.
