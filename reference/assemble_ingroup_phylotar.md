# Assemble Ingroup phylotaR Clusters

Assemble Ingroup phylotaR Clusters

## Usage

``` r
assemble_ingroup_phylotar(
  wd_path,
  target_genes_file = NULL,
  genes_map_file = NULL,
  manual_exclusions_file = NULL,
  min_species = 50,
  preferred_parent = "3593",
  ncbi_dr = NULL,
  force_download = FALSE,
  out_dir = "1_phylotaR_out_Ingroup"
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

- min_species:

  Integer. Minimum species count per cluster to retain. Defaults to 50.

- preferred_parent:

  Character. NCBI taxonomy ID of focal parent. Defaults to "3593"
  (Cactaceae).

- ncbi_dr:

  Character. Path to the local BLAST+ binaries directory. If NULL,
  attempts to auto-detect.

- force_download:

  Logical. If TRUE, executes fresh database calls; if FALSE (default)
  relies on local cache.

- out_dir:

  Character. Directory to save all tables and fasta sequences.
