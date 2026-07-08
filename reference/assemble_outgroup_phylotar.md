# Assemble Outgroup phylotaR Clusters

Assemble Outgroup phylotaR Clusters

## Usage

``` r
assemble_outgroup_phylotar(
  wd_path,
  target_genes_file = NULL,
  genes_map_file = NULL,
  manual_exclusions_file = NULL,
  outgroups = c("107598", "107617", "107583", "3582"),
  force_download = FALSE,
  out_dir = "1_phylotaR_out_Outgroup"
)
```

## Arguments

- wd_path:

  Character. Path to the phylotaR workspace directory (where phylotaR
  cache and parameters are).

- target_genes_file:

  Character. Path to the list of target markers. If NULL, defaults to
  package inst/extdata file.

- genes_map_file:

  Character. Path to the locus mapping CSV file. If NULL, defaults to
  package inst/extdata file.

- manual_exclusions_file:

  Character. Path to the manual exclusions CSV file. If NULL, defaults
  to package inst/extdata file.

- outgroups:

  Character vector of outgroup SIDs to pull clusters for.

- force_download:

  Logical. If TRUE, executes fresh database calls; if FALSE (default)
  relies on local cache.

- out_dir:

  Character. Directory to save all tables and fasta sequences.
