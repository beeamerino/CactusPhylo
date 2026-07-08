# Fetch Genbank Metadata

Fetch Genbank Metadata

## Usage

``` r
fetch_genbank_metadata(
  sids,
  cache_file,
  batch_size = 200,
  sleep_time = 0.5,
  max_retries = 5,
  force_download = FALSE
)
```

## Arguments

- sids:

  A character vector of Sequence IDs to fetch.

- cache_file:

  Character string specifying the cache file path.

- batch_size:

  Integer for download batch size.

- sleep_time:

  Numeric for delay between batches.

- max_retries:

  Integer for maximum retry attempts.

- force_download:

  Logical, if TRUE overrides existing cache.
