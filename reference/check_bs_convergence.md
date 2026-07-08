# Check Bootstrap Convergence

Check Bootstrap Convergence

## Usage

``` r
check_bs_convergence(
  raxml_bin_path,
  bs_trees_file,
  bs_cutoff = 0.03,
  seed = 111,
  threads = 4,
  output_dir = dirname(bs_trees_file),
  prefix = "cactus_bs_convergence"
)
```

## Arguments

- raxml_bin_path:

  Character. RAxML-NG bin path.

- bs_trees_file:

  Character. Path to concatenated bootstrap trees file.

- bs_cutoff:

  Numeric. Cutoff for convergence. Defaults to 0.03.

- seed:

  Integer. Seed. Defaults to 111.

- threads:

  Integer. Threads. Defaults to 4.

- output_dir:

  Character. Directory to write logs. Defaults to
  dirname(bs_trees_file).

- prefix:

  Character. Prefix to use. Defaults to "cactus_bs_convergence".

## Value

Path to convergence log.
