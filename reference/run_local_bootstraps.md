# Run Bootstrap Search Locally

Run Bootstrap Search Locally

## Usage

``` r
run_local_bootstraps(
  raxml_bin_path,
  aln_file,
  part_file,
  constraint_file,
  bs_trees = 500,
  outgroup = NULL,
  seed = 111,
  threads = 8,
  workers = 1,
  output_dir = dirname(aln_file),
  prefix = "cactus_bs"
)
```

## Arguments

- raxml_bin_path:

  Character. System RAxML-NG path.

- aln_file:

  Character. Multiple sequence alignment path.

- part_file:

  Character. Partitions model path.

- constraint_file:

  Character. Constraint tree path.

- bs_trees:

  Integer. Total number of bootstrap trees to generate. Defaults to 500.

- outgroup:

  Character. Outgroup taxon. Defaults to NULL.

- seed:

  Integer. Seed. Defaults to 111.

- threads:

  Integer. Run threads. Defaults to 4.

- workers:

  Integer. Number of workers. Defaults to 1.

- output_dir:

  Character. Directory to write outputs.

- prefix:

  Character. Output prefix. Defaults to "cactus_bs".

## Value

Output bootstrap trees file.
