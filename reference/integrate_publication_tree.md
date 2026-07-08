# Render Final Publication Figures and Registry

Render Final Publication Figures and Registry

## Usage

``` r
integrate_publication_tree(
  ml_support_tree_path,
  summary_chronogram_path,
  constraints_path,
  out_dir,
  collapse_cutoff = 0.7
)
```

## Arguments

- ml_support_tree_path:

  Character. Best ML support tree path.

- summary_chronogram_path:

  Character. Chronogram path with HPD annotations.

- constraints_path:

  Character. Taxonomy constraints CSV path.

- out_dir:

  Character. Publication figures directory.

- collapse_cutoff:

  Numeric. TBE threshold to collapse nodes (0.0 to 1.0).

## Value

A matrix listing exported items and verification parameters.
