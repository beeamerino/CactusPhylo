# Generate Chunk Bootstrap Shell Script

Generate Chunk Bootstrap Shell Script

## Usage

``` r
generate_bootstrap_script(
  alignment_file,
  partition_file,
  constraint_file,
  outgroup = NULL,
  bs_per_rep = 500,
  max_reps = 4,
  base_seed = 111,
  seed_step = 1000,
  threads = 120,
  workers = 20,
  output_dir = getwd(),
  script_name = "run_bs_chunks.sh",
  cluster_job_name = "C-raxml.bs",
  cluster_mem = "32G",
  cluster_time = "7-00:00",
  cluster_partition = "general",
  cluster_queue = "public",
  load_module = "raxml-ng-1.1.0-gcc-11.2.0",
  raxml_exec = "raxml-ng-mpi"
)
```

## Arguments

- alignment_file:

  Character. Alignment file path.

- partition_file:

  Character. Partition model file path.

- constraint_file:

  Character. Constraint tree file path.

- outgroup:

  Character. Outgroup taxon. Defaults to NULL.

- bs_per_rep:

  Integer. Bootstraps per replicate. Defaults to 500.

- max_reps:

  Integer. Number of chunks. Defaults to 4.

- base_seed:

  Integer. Base seed. Defaults to 111.

- seed_step:

  Integer. Step in seed increments per chunk. Defaults to 1000.

- threads:

  Integer. Threads per task. Defaults to 120.

- workers:

  Integer. Workers per task. Defaults to 20.

- output_dir:

  Character. Where to output scripts and chunks.

- script_name:

  Character. The name of the bash file.

- cluster_job_name:

  Character. Job name for SLURM. Defaults to "C-raxml-bs".

- cluster_mem:

  Character. Memory for SLURM. Defaults to "32G".

- cluster_time:

  Character. Time limit for SLURM. Defaults to "7-00:00".

- cluster_partition:

  Character. Partition for SLURM. Defaults to "general".

- cluster_queue:

  Character. Queue for SLURM. Defaults to "public".

- load_module:

  Character. Module to load in SLURM script. Defaults to
  "raxml-ng-1.1.0-gcc-11.2.0".

- raxml_exec:

  Character. RAxML executable to use. Defaults to "raxml-ng-mpi".

## Value

The path to the generated script.
