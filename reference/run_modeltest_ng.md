# Run ModelTest-NG Partition Evaluations

Run ModelTest-NG Partition Evaluations

## Usage

``` r
run_modeltest_ng(
  modeltest_exec_path,
  aln_file,
  part_file,
  prefix = "MODELTEST_cactus_phylo",
  threads = 4
)
```

## Arguments

- modeltest_exec_path:

  Character. Path to ModelTest-NG.

- aln_file:

  Character. Checked PHYLIP alignment path.

- part_file:

  Character. Cleaned partitions path.

- prefix:

  Character. File output prefix.

- threads:

  Integer. Processing threads count.

## Value

Character path to the resulting partition map file.
