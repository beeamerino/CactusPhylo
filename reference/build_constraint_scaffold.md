# Generate Newick Constraint Scaffold

Generate Newick Constraint Scaffold

## Usage

``` r
build_constraint_scaffold(
  alignment_path,
  constraints_csv_path,
  output_dir = dirname(alignment_path)
)
```

## Arguments

- alignment_path:

  Character. Path to input PHYLIP file.

- constraints_csv_path:

  Character. Path to the taxonomy CSV.

- output_dir:

  Character. Directory to write outputs. Defaults to the alignment
  path's directory.

## Value

Character. The file path to the saved constraint tree.
