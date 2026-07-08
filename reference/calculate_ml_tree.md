# Execute ML Search in RAxML-NG

Execute ML Search in RAxML-NG

## Usage

``` r
calculate_ml_tree(
  raxml_bin_path,
  aln_file,
  part_file,
  constraint_file,
  outgroup = NULL,
  n_init_trees = "rand{25},pars{25}",
  seed = 111,
  n_workers = 1,
  threads = 4,
  output_dir = dirname(aln_file),
  prefix = "cactus_search"
)
```

## Arguments

- raxml_bin_path:

  Character. System RAxML-NG path.

- aln_file:

  Character. PHYLIP matrix path.

- part_file:

  Character. Partitions model path.

- constraint_file:

  Character. Constraints scaffold tree path.

- outgroup:

  Character. Outgroup species name to root the tree. Defaults to NULL.

- n_init_trees:

  Character. Initial trees configuration for search. Defaults to
  "rand25,pars25".

- seed:

  Integer. Seed for reproducibility. Defaults to 111.

- n_workers:

  Integer. Number of workers. Defaults to 1.

- threads:

  Integer. Run threads.

- output_dir:

  Character. Directory to write outputs. Defaults to aln_file directory.

- prefix:

  Character. Prefix for output files. Defaults to "cactus_search".

## Value

List of output paths.
