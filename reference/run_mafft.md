# Run MAFFT Alignment

Run MAFFT Alignment

## Usage

``` r
run_mafft(
  input_fasta,
  output_fasta,
  mafft_exec = "mafft",
  mafft_opts = "--auto"
)
```

## Arguments

- input_fasta:

  Character. Input FASTA file path.

- output_fasta:

  Character. Output aligned FASTA path.

- mafft_exec:

  Character. System MAFFT binary location.

- mafft_opts:

  Character. Parameters passed to MAFFT.

## Value

Numeric. Exit status code.
