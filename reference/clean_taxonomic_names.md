# Reconcile and Validate Taxonomic Names

Reconcile and Validate Taxonomic Names

## Usage

``` r
clean_taxonomic_names(
  raw_input_fasta,
  checklist_path,
  output_clean_dir,
  force_process = FALSE
)
```

## Arguments

- raw_input_fasta:

  Character path. Raw download coordinates folder.

- checklist_path:

  Character. Excel Cactaceae accepted spelling table file.

- output_clean_dir:

  Character. Folders for cleaned configurations.

- force_process:

  Logical. Skip cache check.
