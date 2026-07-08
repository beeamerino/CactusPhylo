#' Preprocess Partitions and Run Alignment Check
#'
#' @param phy_matrix Character. Input PHYLIP file path.
#' @param part_file Character. Input partition mapping file.
#' @param raxml_path Character. Location of the RAxML-NG executable.
#' @param output_dir Character. Folders for validated partitions outputs. Defaults to dirname(phy_matrix).
#' @param force_check Logical. Bypass run checks if validation exists.
#' @export
preprocess_partitions <- function(phy_matrix, part_file, raxml_path, output_dir = dirname(phy_matrix), force_check = FALSE) {
  
  if (Sys.which(raxml_path) == "") {
    stop("Executable '", raxml_path, "' not found in your system's PATH.\n",
         "Please ensure RAxML-NG is installed and available, or provide the full absolute path.")
  }

  clean_part <- file.path(output_dir, "cactus_check.raxml.reduced.clean.partition")
  if (!force_check && file.exists(clean_part)) {
    message("CACHE: Partition validation checked already, loading: ", clean_part)
    return(clean_part)
  }
  
  prefix_check <- file.path(output_dir, "cactus_check")
  
  # Run system raxmlcheck validation
  aln_check <- system2(
    raxml_path,
    args = c(
      "--check",
      "--msa", shQuote(phy_matrix),
      "--model", shQuote(part_file),
      "--prefix", shQuote(prefix_check),
      "--threads 4"
    ),
    stdout = "",
    stderr = ""
  )
  
  # Read reduced output partition generated from check
  reduced_part_file <- file.path(output_dir, "cactus_check.raxml.reduced.partition")
  if (!file.exists(reduced_part_file)) {
    stop("Alignment validation check failed to create: ", reduced_part_file)
  }
  
  lines <- readLines(reduced_part_file, warn = FALSE)
  
  # Modeling to DNA replacements formatting
  dna_lines <- sub("^[^,]+,", "DNA,", lines)
  
  writeLines(dna_lines, clean_part)
  return(clean_part)
}

#' Run ModelTest-NG Partition Evaluations
#'
#' @param modeltest_exec_path Character. Path to ModelTest-NG.
#' @param aln_file Character. Checked PHYLIP alignment path.
#' @param part_file Character. Cleaned partitions path.
#' @param prefix Character. File output prefix.
#' @param threads Integer. Processing threads count.
#' @return Character path to the resulting partition map file.
#' @export
run_modeltest_ng <- function(modeltest_exec_path, aln_file, part_file, prefix = "MODELTEST_cactus_phylo", threads = 4) {
  
  if (Sys.which(modeltest_exec_path) == "") {
    stop("Executable '", modeltest_exec_path, "' not found in your system's PATH.\n",
         "Please ensure ModelTest-NG is installed and available, or provide the full absolute path.")
  }

  # Invocation parameters setup
  args <- c(
    "--datatype", "nt",
    "--input", shQuote(aln_file),
    "--partitions", shQuote(part_file),
    "--output", shQuote(prefix),
    "--processes", as.character(threads),
    "--template", "raxml"
  )
  
  message("Executing ModelTest-NG over partitions database...")
  exit_status <- system2(
    command = modeltest_exec_path,
    args = args,
    stdout = TRUE,
    stderr = TRUE
  )
  
  # Best model file returned path
  expected_out <- paste0(prefix, ".part.aicc")
  return(expected_out)
}

#' Generate Newick Constraint Scaffold
#'
#' @param alignment_path Character. Path to input PHYLIP file.
#' @param constraints_csv_path Character. Path to the taxonomy CSV.
#' @param output_dir Character. Directory to write outputs. Defaults to the alignment path's directory.
#' @return Character. The file path to the saved constraint tree.
#' @export
build_constraint_scaffold <- function(alignment_path, constraints_csv_path, output_dir = dirname(alignment_path)) {
  
  if (!dir.exists(output_dir)) {
    dir.create(output_dir, recursive = TRUE, showWarnings = FALSE)
  }
  
  out_missing     <- file.path(output_dir, "TABLE_cactus_alignment_taxa_missing_from_constraints.csv")
  out_dup_clade   <- file.path(output_dir, "TABLE_cactus_constraint_duplicate_clade_membership.csv")
  out_clade_sizes <- file.path(output_dir, "TABLE_cactus_constraint_clade_sizes.csv")
  out_tree        <- file.path(output_dir, "cactus_constraints.tree")
  out_log         <- file.path(output_dir, "LOG_cactus_constraint_tree.txt")
  
  log_message <- function(...) {
    msg <- paste0(...)
    timestamped <- paste0("[", format(Sys.time(), "%Y-%m-%d %H:%M:%S"), "] ", msg)
    message(timestamped)
    cat(timestamped, "\n", file = out_log, append = TRUE)
  }
  
  if (file.exists(out_log)) file.remove(out_log)
  log_message("Starting constraint tree construction.")
  
  # 1. VALIDATE AND READ ALIGNMENT
  if (!file.exists(alignment_path)) stop("Missing alignment: ", alignment_path)
  if (!file.exists(constraints_csv_path)) stop("Missing constraints table: ", constraints_csv_path)
  
  aln <- tryCatch(
    ape::read.dna(alignment_path, format = "sequential"),
    error = function(e) stop("Could not read alignment at ", alignment_path, " | ", conditionMessage(e))
  )
  
  species_alignment <- rownames(aln)
  if (is.null(species_alignment) || length(species_alignment) == 0) {
    stop("No taxa found in alignment: ", alignment_path)
  }
  species_alignment <- sort(unique(species_alignment))
  log_message("Alignment taxa loaded: ", length(species_alignment))
  
  # 2. READ CONSTRAINTS
  cf_all <- tryCatch(
    read.csv(constraints_csv_path, stringsAsFactors = FALSE),
    error = function(e) stop("Could not read constraints table at ", constraints_csv_path, " | ", conditionMessage(e))
  )
  
  required_cols <- c("Specie_name", "Clade", "Subfam", "Family")
  missing_cols <- setdiff(required_cols, colnames(cf_all))
  if (length(missing_cols) > 0) stop("Missing required columns in constraints table: ", paste(missing_cols, collapse = ", "))
  
  cf_all$Specie_name <- trimws(cf_all$Specie_name)
  cf_all$Clade       <- trimws(cf_all$Clade)
  cf_all$Subfam      <- trimws(cf_all$Subfam)
  cf_all$Family      <- trimws(cf_all$Family)
  
  if (any(is.na(cf_all$Specie_name)) || any(cf_all$Specie_name == "")) stop("Constraints table contains empty or NA values in Specie_name.")
  if (any(is.na(cf_all$Clade)) || any(cf_all$Clade == "")) stop("Constraints table contains empty or NA values in Clade.")
  
  log_message("Constraint rows loaded: ", nrow(cf_all))
  
  # 3. COVERAGE AND CONSISTENCY AUDITS
  missing_taxa <- setdiff(species_alignment, cf_all$Specie_name)
  if (length(missing_taxa) > 0) {
    write.csv(data.frame(Species_missing = missing_taxa), out_missing, row.names = FALSE)
    stop(length(missing_taxa), " taxa in the alignment are missing from constraints table. ",
         "Missing list written to: ", out_missing)
  }
  
  log_message("All alignment taxa are represented in constraints table.")
  
  # Check duplicates
  cf_align <- cf_all[cf_all$Specie_name %in% species_alignment, ]
  cf_unique <- unique(cf_align[, c("Specie_name", "Clade")])
  dup_counts <- table(cf_unique$Specie_name)
  true_dups <- names(dup_counts[dup_counts > 1])
  
  if (length(true_dups) > 0) {
    dup_detail <- cf_unique[cf_unique$Specie_name %in% true_dups, ]
    dup_detail <- dup_detail[order(dup_detail$Specie_name, dup_detail$Clade), ]
    write.csv(dup_detail, out_dup_clade, row.names = FALSE)
    stop("Species assigned to multiple clades detected. Details written to: ", out_dup_clade)
  }
  
  log_message("No duplicate clade membership detected among alignment taxa.")
  
  # 4. FILTER TO ALIGNMENT TAXA
  cf <- unique(cf_align)
  cf$Genus <- sub("_.*$", "", cf$Specie_name)
  
  genus_to_constraint <- character(0)
  target_genera <- sort(intersect(unique(cf$Genus), genus_to_constraint))
  log_message("Genera with additional genus-level constraints: ",
              ifelse(length(target_genera) == 0, "none", paste(target_genera, collapse = ", ")))
  
  genus_newick_lut <- NULL
  if (length(target_genera) > 0) {
    # Emulate group_by collapse
    spp_by_genus <- split(cf$Specie_name, cf$Genus)
    spp_by_genus <- spp_by_genus[names(spp_by_genus) %in% target_genera]
    genus_newick_lut <- sapply(spp_by_genus, function(spp) {
      paste0("(", paste(sort(unique(spp)), collapse = ","), ")")
    })
  }
  
  # Helper
  extract_required_clade <- function(df, clade_name) {
    res <- sort(unique(df$Specie_name[df$Clade == clade_name]))
    if (length(res) == 0) stop("Required clade missing or empty in constraints table: ", clade_name)
    return(res)
  }
  
  collapse_clade <- function(x, genus_newick_lut = NULL) {
    if (length(x) == 0) return("")
    
    x <- sort(unique(x))
    genus_vec <- sub("_.*$", "", x)
    
    if (!is.null(genus_newick_lut) && length(genus_newick_lut) > 0) {
      grouped <- split(x, genus_vec)
      new_elements <- character(0)
      
      for (g in sort(names(grouped))) {
        if (g %in% names(genus_newick_lut)) {
          new_elements <- c(new_elements, genus_newick_lut[[g]])
        } else {
          new_elements <- c(new_elements, sort(grouped[[g]]))
        }
      }
      x <- sort(unique(new_elements))
    }
    
    if (length(x) == 1) return(x)
    return(paste0("(", paste(x, collapse = ","), ")"))
  }
  
  # 5. EXTRACT REQUIRED CLADES
  clades <- list(
    talinopsis    = extract_required_clade(cf, "Talinopsis"),
    grahamia      = extract_required_clade(cf, "Grahamia"),
    anacampseros  = extract_required_clade(cf, "Anacampseros"),
    portulaca     = extract_required_clade(cf, "Portulaca"),
    leuenbergeria = extract_required_clade(cf, "Leuenbergeria"),
    pereskia      = extract_required_clade(cf, "Pereskia"),
    tephrocacteae = extract_required_clade(cf, "Tephrocacteae"),
    cylindropuntieae = extract_required_clade(cf, "Cylindropuntieae"),
    opuntieae     = extract_required_clade(cf, "Opuntieae"),
    maihuenia     = extract_required_clade(cf, "Maihuenia"),
    blossfeldia   = extract_required_clade(cf, "Blossfeldia"),
    core_I        = extract_required_clade(cf, "Core I"),
    rhipsalideae  = extract_required_clade(cf, "Rhipsalideae"),
    notocacteae   = extract_required_clade(cf, "Notocacteae"),
    bct_core      = extract_required_clade(cf, "BCT"),
    calymmanthium = extract_required_clade(cf, "Calymmanthium"),
    copiapoa      = extract_required_clade(cf, "Copiapoa"),
    frailea       = extract_required_clade(cf, "Frailea"),
    cacteae       = extract_required_clade(cf, "Cacteae")
  )
  
  clade_sizes <- data.frame(
    clade = names(clades),
    n_taxa = vapply(clades, length, integer(1)),
    stringsAsFactors = FALSE
  )
  clade_sizes <- clade_sizes[order(clade_sizes$clade), ]
  write.csv(clade_sizes, out_clade_sizes, row.names = FALSE)
  log_message("Clade size summary written to: ", out_clade_sizes)
  
  # 6. COLLAPSE CLADES TO NEWICK STRINGS
  s_tal   <- collapse_clade(clades$talinopsis, genus_newick_lut)
  s_gra   <- collapse_clade(clades$grahamia, genus_newick_lut)
  s_ana   <- collapse_clade(clades$anacampseros, genus_newick_lut)
  s_por   <- collapse_clade(clades$portulaca, genus_newick_lut)
  
  s_leu   <- collapse_clade(clades$leuenbergeria, genus_newick_lut)
  s_per   <- collapse_clade(clades$pereskia, genus_newick_lut)
  s_teph  <- collapse_clade(clades$tephrocacteae, genus_newick_lut)
  s_cyl   <- collapse_clade(clades$cylindropuntieae, genus_newick_lut)
  s_opu   <- collapse_clade(clades$opuntieae, genus_newick_lut)
  s_mai   <- collapse_clade(clades$maihuenia, genus_newick_lut)
  s_blo   <- collapse_clade(clades$blossfeldia, genus_newick_lut)
  s_coreI  <- collapse_clade(clades$core_I, genus_newick_lut)
  s_rhip <- collapse_clade(clades$rhipsalideae, genus_newick_lut)
  s_noto <- collapse_clade(clades$notocacteae, genus_newick_lut)
  s_bct <- collapse_clade(clades$bct_core, genus_newick_lut)
  s_caly  <- collapse_clade(clades$calymmanthium, genus_newick_lut)
  s_copi  <- collapse_clade(clades$copiapoa, genus_newick_lut)
  s_frai  <- collapse_clade(clades$frailea, genus_newick_lut)
  s_cact  <- collapse_clade(clades$cacteae, genus_newick_lut)
  
  # 7. BUILD FIXED TOPOLOGY
  s_outgroup <- paste0("(", s_por, ",(", s_tal, ",(", s_gra, ",", s_ana, ")))")
  s_opuntioideae <- paste0("(", s_cyl, ",(", s_teph, ",", s_opu, "))")
  s_coreII <- paste0("(", s_rhip, ",(", s_noto, ",", s_bct, "))")
  s_core_cactoideae <- paste0("(", s_frai, ",", s_caly, ",", s_copi, ",(", s_coreII, ",", s_coreI, "))")
  s_cactoideae <- paste0("(", s_cact, ",", s_core_cactoideae, ")")
  s_cactaceae <- paste0("(", s_leu, ",(", s_per, ",(", s_opuntioideae, ",(", s_mai, ",(", s_blo, ",", s_cactoideae, ")))))")
  
  constraint_tree <- paste0("(", s_outgroup, ",", s_cactaceae, ");")
  constraint_tree <- gsub("\\s+", "", constraint_tree)
  log_message("Constraint tree string constructed.")
  
  # 8. VALIDATE TREE
  tree_obj <- tryCatch(
    ape::read.tree(text = constraint_tree),
    error = function(e) stop("Generated Newick is invalid: ", conditionMessage(e))
  )
  
  if (is.null(tree_obj$tip.label) || length(tree_obj$tip.label) == 0) {
    stop("Generated tree has no tip labels.")
  }
  
  tree_tips <- sort(unique(tree_obj$tip.label))
  if (!setequal(tree_tips, species_alignment)) {
    missing_in_tree <- setdiff(species_alignment, tree_tips)
    extra_in_tree <- setdiff(tree_tips, species_alignment)
    
    detail_msg <- paste0(
      "Final constraint tree tips do not match alignment taxa.",
      if (length(missing_in_tree) > 0) paste0(" Missing in tree: ", paste(missing_in_tree, collapse = ", "), ".") else "",
      if (length(extra_in_tree) > 0) paste0(" Extra in tree: ", paste(extra_in_tree, collapse = ", "), ".") else ""
    )
    stop(detail_msg)
  }
  
  if (anyDuplicated(tree_obj$tip.label) > 0) stop("Generated tree contains duplicated tip labels.")
  
  log_message("Tree parsed successfully.")
  log_message("Tree tips: ", length(tree_obj$tip.label))
  log_message("Tree is binary: ", ape::is.binary(tree_obj))
  
  # 9. EXPORT TREE
  writeLines(constraint_tree, con = out_tree)
  log_message("Constraint tree written to: ", out_tree)
  log_message("Constraint tree newick length: ", nchar(constraint_tree))
  log_message("Run finished successfully.")
  
  return(out_tree)
}

#' Execute ML Search in RAxML-NG
#'
#' @param raxml_bin_path Character. System RAxML-NG path.
#' @param aln_file Character. PHYLIP matrix path.
#' @param part_file Character. Partitions model path.
#' @param constraint_file Character. Constraints scaffold tree path.
#' @param outgroup Character. Outgroup species name to root the tree. Defaults to NULL.
#' @param n_init_trees Character. Initial trees configuration for search. Defaults to "rand{25},pars{25}".
#' @param seed Integer. Seed for reproducibility. Defaults to 111.
#' @param n_workers Integer. Number of workers. Defaults to 1.
#' @param threads Integer. Run threads.
#' @param output_dir Character. Directory to write outputs. Defaults to aln_file directory.
#' @param prefix Character. Prefix for output files. Defaults to "cactus_search".
#' @return List of output paths.
#' @export
calculate_ml_tree <- function(raxml_bin_path, aln_file, part_file, constraint_file, 
                              outgroup = NULL, n_init_trees = "rand{25},pars{25}",
                              seed = 111, n_workers = 1, threads = 4, 
                              output_dir = dirname(aln_file), prefix = "cactus_search") {
  
  if (Sys.which(raxml_bin_path) == "") {
    stop("Executable '", raxml_bin_path, "' not found in your system's PATH.\n",
         "Please ensure RAxML-NG is installed and available, or provide the full absolute path.")
  }

  if (!dir.exists(output_dir)) {
    dir.create(output_dir, recursive = TRUE, showWarnings = FALSE)
  }
  
  out_prefix <- file.path(output_dir, prefix)
  
  args <- c(
    "--msa", shQuote(aln_file),
    "--model", shQuote(part_file),
    "--tree-constraint", shQuote(constraint_file),
    "--tree", shQuote(n_init_trees),
    "--seed", as.character(seed),
    "--workers", as.character(n_workers),
    "--threads", as.character(threads),
    "--prefix", shQuote(out_prefix)
  )
  
  if (!is.null(outgroup) && outgroup != "") {
    args <- c(args, "--outgroup", shQuote(outgroup))
  }
  
  system2(command = raxml_bin_path, args = args)
  
  message("\nMaximum-likelihood tree calculation completed. \U0001f335")
  return(list(
    bestTree = paste0(out_prefix, ".raxml.bestTree"),
    mlTrees  = paste0(out_prefix, ".raxml.mlTrees")
  ))
}

#' Calculate and Burn Branch Supports
#'
#' @param raxml_bin Character. System RAxML-NG path.
#' @param best_tree Character. Best tree topology path.
#' @param bootstraps_file Character. Replicates tree file path.
#' @param metric Character. Support type ('tbe' or 'fbp').
#' @param threads Integer. Calculations threads count.
#' @param output_dir Character. Directory to write the support file. Defaults to dirname(best_tree).
#' @param prefix Character. Output prefix. Defaults to "cactus_support".
#' @return Character path to the written support tree.
#' @export
map_branch_supports <- function(raxml_bin, best_tree, bootstraps_file, metric = "tbe", threads = 4, output_dir = dirname(best_tree), prefix = "cactus_support") {
  
  if (Sys.which(raxml_bin) == "") {
    stop("Executable '", raxml_bin, "' not found in your system's PATH.\n",
         "Please ensure RAxML-NG is installed and available, or provide the full absolute path.")
  }

  if (!dir.exists(output_dir)) dir.create(output_dir, recursive = TRUE, showWarnings = FALSE)
  out_prefix <- file.path(output_dir, prefix)
  
  args <- c(
    "--support",
    "--tree", shQuote(best_tree),
    "--bs-trees", shQuote(bootstraps_file),
    "--bs-metric", shQuote(metric),
    "--threads", as.character(threads),
    "--prefix", shQuote(out_prefix)
  )
  
  system2(command = raxml_bin, args = args)
  return(paste0(out_prefix, ".raxml.support"))
}

#' Compute Robinson-Foulds Distances between Maximum-Likelihood Trees
#'
#' @param raxml_bin_path Character. System RAxML-NG path.
#' @param ml_trees_file Character. Path to .raxml.mlTrees file.
#' @param output_dir Character. Directory for outputs. Defaults to ml_trees_file directory.
#' @param prefix Character. Output prefix. Defaults to "cactus_RF".
#' @return Output prefix distance path.
#' @export
calculate_rf_distances <- function(raxml_bin_path, ml_trees_file, output_dir = dirname(ml_trees_file), prefix = "cactus_RF") {
  
  if (!dir.exists(output_dir)) dir.create(output_dir, recursive = TRUE, showWarnings = FALSE)
  out_prefix <- file.path(output_dir, prefix)
  
  args <- c(
    "--rfdist",
    "--tree", shQuote(ml_trees_file),
    "--prefix", shQuote(out_prefix)
  )
  
  system2(command = raxml_bin_path, args = args)
  return(paste0(out_prefix, ".raxml.rfdist"))
}

#' Run Bootstrap Search Locally
#'
#' @param raxml_bin_path Character. System RAxML-NG path.
#' @param aln_file Character. Multiple sequence alignment path.
#' @param part_file Character. Partitions model path.
#' @param constraint_file Character. Constraint tree path.
#' @param bs_trees Integer. Total number of bootstrap trees to generate. Defaults to 500.
#' @param outgroup Character. Outgroup taxon. Defaults to NULL.
#' @param seed Integer. Seed. Defaults to 111.
#' @param threads Integer. Run threads. Defaults to 4.
#' @param workers Integer. Number of workers. Defaults to 1.
#' @param output_dir Character. Directory to write outputs.
#' @param prefix Character. Output prefix. Defaults to "cactus_bs".
#' @return Output bootstrap trees file.
#' @export
run_local_bootstraps <- function(raxml_bin_path, aln_file, part_file, constraint_file,
                                 bs_trees = 500, outgroup = NULL, seed = 111,
                                 threads = 8, workers = 1, output_dir = dirname(aln_file),
                                 prefix = "cactus_bs") {
                                 
  if (Sys.which(raxml_bin_path) == "") {
    stop("Executable '", raxml_bin_path, "' not found in your system's PATH.\n",
         "Please ensure RAxML-NG is installed and available, or provide the full absolute path.")
  }

  if (!dir.exists(output_dir)) dir.create(output_dir, recursive = TRUE, showWarnings = FALSE)
  out_prefix <- file.path(output_dir, prefix)
  
  args <- c(
    "--bootstrap",
    "--msa", shQuote(aln_file),
    "--model", shQuote(part_file),
    "--tree-constraint", shQuote(constraint_file),
    "--bs-trees", as.character(bs_trees),
    "--bs-metric", "tbe",
    "--seed", as.character(seed),
    "--workers", as.character(workers),
    "--threads", as.character(threads),
    "--prefix", shQuote(out_prefix)
  )
  
  if (!is.null(outgroup) && outgroup != "") {
    args <- c(args, "--outgroup", shQuote(outgroup))
  }
  
  system2(command = raxml_bin_path, args = args)
  return(paste0(out_prefix, ".raxml.bootstraps"))
}

#' Generate Chunk Bootstrap Shell Script
#'
#' @param alignment_file Character. Alignment file path.
#' @param partition_file Character. Partition model file path.
#' @param constraint_file Character. Constraint tree file path.
#' @param outgroup Character. Outgroup taxon. Defaults to NULL.
#' @param bs_per_rep Integer. Bootstraps per replicate. Defaults to 500.
#' @param max_reps Integer. Number of chunks. Defaults to 4.
#' @param base_seed Integer. Base seed. Defaults to 111.
#' @param seed_step Integer. Step in seed increments per chunk. Defaults to 1000.
#' @param threads Integer. Threads per task. Defaults to 120.
#' @param workers Integer. Workers per task. Defaults to 20.
#' @param output_dir Character. Where to output scripts and chunks.
#' @param script_name Character. The name of the bash file.
#' @param cluster_job_name Character. Job name for SLURM. Defaults to "C-raxml-bs".
#' @param cluster_mem Character. Memory for SLURM. Defaults to "32G".
#' @param cluster_time Character. Time limit for SLURM. Defaults to "7-00:00".
#' @param cluster_partition Character. Partition for SLURM. Defaults to "general".
#' @param cluster_queue Character. Queue for SLURM. Defaults to "public".
#' @param load_module Character. Module to load in SLURM script. Defaults to "raxml-ng-1.1.0-gcc-11.2.0".
#' @param raxml_exec Character. RAxML executable to use. Defaults to "raxml-ng-mpi".
#' @return The path to the generated script.
#' @export
generate_bootstrap_script <- function(alignment_file, partition_file, constraint_file,
                                      outgroup = NULL, bs_per_rep = 500, max_reps = 4,
                                      base_seed = 111, seed_step = 1000, 
                                      threads = 120, workers = 20,
                                      output_dir = getwd(),
                                      script_name = "run_bs_chunks.sh",
                                      cluster_job_name = "C-raxml.bs", 
                                      cluster_mem = "32G", cluster_time = "7-00:00",
                                      cluster_partition = "general", cluster_queue = "public",
                                      load_module = "raxml-ng-1.1.0-gcc-11.2.0",
                                      raxml_exec = "raxml-ng-mpi") {
  
  bs_dir <- file.path(output_dir, "bs_chunks")
  if (!dir.exists(bs_dir)) dir.create(bs_dir, recursive = TRUE)
  
  bash_script <- file.path(bs_dir, script_name)
  cat("#!/bin/bash\n", file = bash_script)
  cat(paste0("#SBATCH -J ", cluster_job_name, "\n"), file = bash_script, append = TRUE)
  cat("#SBATCH --nodes=1\n", file = bash_script, append = TRUE)
  cat("#SBATCH --ntasks-per-node=1\n", file = bash_script, append = TRUE)
  cat(paste0("#SBATCH --cpus-per-task=", threads, "\n"), file = bash_script, append = TRUE)
  cat(paste0("#SBATCH --mem=", cluster_mem, "\n"), file = bash_script, append = TRUE)
  cat(paste0("#SBATCH -t ", cluster_time, "\n"), file = bash_script, append = TRUE)
  cat(paste0("#SBATCH -p ", cluster_partition, "\n"), file = bash_script, append = TRUE)
  cat(paste0("#SBATCH -q ", cluster_queue, "\n"), file = bash_script, append = TRUE)
  cat("#SBATCH --mail-type=ALL\n", file = bash_script, append = TRUE)
  cat("#\n\n", file = bash_script, append = TRUE)
  
  if (!is.null(load_module) && load_module != "") {
    cat(paste0("module load ", load_module, "\n\n"), file = bash_script, append = TRUE)
  }
  
  for (i in 1:max_reps) {
    seed_i <- base_seed + i * seed_step
    rep_dir <- file.path(bs_dir, sprintf("bs_rep_%02d", i))
    
    prefix_i <- file.path(rep_dir, sprintf("cactus_bs_rep_%02d", i))
    
    cmd <- paste0(
      "echo \"Running bootstrap replica ", i, " (", bs_per_rep, " BS, seed ", seed_i, ")\"\n",
      "mkdir -p ", shQuote(rep_dir), "\n",
      raxml_exec, " --bootstrap ",
      "--msa ", shQuote(alignment_file), " ",
      "--model ", shQuote(partition_file), " ",
      "--tree-constraint ", shQuote(constraint_file), " "
    )
    if (!is.null(outgroup) && outgroup != "") {
      cmd <- paste0(cmd, "--outgroup ", shQuote(outgroup), " ")
    }
    cmd <- paste0(cmd,
      "--bs-trees ", bs_per_rep, " ",
      "--bs-metric tbe ",
      "--threads ", threads, " ",
      "--workers ", workers, " ",
      "--seed ", seed_i, " ",
      "--prefix ", shQuote(prefix_i), "\n\n"
    )
    cat(cmd, file = bash_script, append = TRUE)
  }
  
  system(paste("chmod +x", shQuote(bash_script)))
  message("Bash script ready: ", bash_script)
  return(bash_script)
}

#' Collect Bootstrap Trees
#'
#' @param bs_dir Character. Directory where bootstraps chunks are stored.
#' @param output_dir Character. Directory to write concatenated bootstraps. Defaults to bs_dir.
#' @param prefix Character. Prefix to use. Defaults to "cactus_ALL_bootstraps".
#' @return Path to concatenated trees file.
#' @export
collect_bootstraps <- function(bs_dir, output_dir = bs_dir, prefix = "cactus_ALL_bootstraps") {
  
  bs_files <- list.files(bs_dir, pattern = "\\.raxml\\.bootstraps$", recursive = TRUE, full.names = TRUE)
  if (length(bs_files) == 0) {
    stop("No BS files found in ", bs_dir)
  }
  
  message("Found ", length(bs_files), " BS files")
  
  all_bs_trees <- unlist(lapply(bs_files, ape::read.tree), recursive = FALSE)
  
  if (!dir.exists(output_dir)) dir.create(output_dir, recursive = TRUE, showWarnings = FALSE)
  bs_concat_file <- file.path(output_dir, paste0(prefix, ".tree"))
  ape::write.tree(all_bs_trees, file = bs_concat_file)
  
  message("BS trees (", length(all_bs_trees), " total) concatenated to: ", bs_concat_file)
  return(bs_concat_file)
}

#' Check Bootstrap Convergence
#'
#' @param raxml_bin_path Character. RAxML-NG bin path.
#' @param bs_trees_file Character. Path to concatenated bootstrap trees file.
#' @param bs_cutoff Numeric. Cutoff for convergence. Defaults to 0.03.
#' @param seed Integer. Seed. Defaults to 111.
#' @param threads Integer. Threads. Defaults to 4.
#' @param output_dir Character. Directory to write logs. Defaults to dirname(bs_trees_file).
#' @param prefix Character. Prefix to use. Defaults to "cactus_bs_convergence".
#' @return Path to convergence log.
#' @export
check_bs_convergence <- function(raxml_bin_path, bs_trees_file, bs_cutoff = 0.03,
                                 seed = 111, threads = 4, 
                                 output_dir = dirname(bs_trees_file), prefix = "cactus_bs_convergence") {
  
  if (!dir.exists(output_dir)) dir.create(output_dir, recursive = TRUE, showWarnings = FALSE)
  out_prefix <- file.path(output_dir, prefix)
  
  args <- c(
    "--bsconverge",
    "--bs-trees", shQuote(bs_trees_file),
    "--bs-metric", "tbe",
    "--bs-cutoff", as.character(bs_cutoff),
    "--seed", as.character(seed),
    "--threads", as.character(threads),
    "--prefix", shQuote(out_prefix)
  )
  
  system2(command = raxml_bin_path, args = args)
  return(paste0(out_prefix, ".raxml.log"))
}

#' Compute Temporal Best Maximum-Likelihood Tree Constrained Bootstrap Replicates
#'
#' @param raxml_bin_path Character. System RAxML-NG path.
#' @param aln_file Character. Multiple sequence alignment path.
#' @param part_file Character. Partitions model path.
#' @param best_tree_file Character. Best tree topology path (used as constraint).
#' @param bs_trees Integer. Bootstrap replicates for temporal analysis. Defaults to 500.
#' @param outgroup Character. Outgroup taxon. Defaults to NULL.
#' @param seed Integer. Seed. Defaults to 111.
#' @param threads Integer. Run threads.
#' @param output_dir Character. Directory to write outputs.
#' @param prefix Character. Output prefix. Defaults to "cactus_temporal".
#' @return Output bootstrap trees file.
#' @export
calculate_temporal_bootstraps <- function(raxml_bin_path, aln_file, part_file, best_tree_file,
                                          bs_trees = 500, outgroup = NULL, seed = 111,
                                          threads = 4, output_dir = dirname(aln_file),
                                          prefix = "cactus_temporal") {
                                          
  if (Sys.which(raxml_bin_path) == "") {
    stop("Executable '", raxml_bin_path, "' not found in your system's PATH.\n",
         "Please ensure RAxML-NG is installed and available, or provide the full absolute path.")
  }

  if (!dir.exists(output_dir)) dir.create(output_dir, recursive = TRUE, showWarnings = FALSE)
  out_prefix <- file.path(output_dir, prefix)
  
  args <- c(
    "--bootstrap",
    "--msa", shQuote(aln_file),
    "--model", shQuote(part_file),
    "--tree-constraint", shQuote(best_tree_file),
    "--bs-trees", as.character(bs_trees),
    "--bs-metric", "tbe",
    "--seed", as.character(seed),
    "--threads", as.character(threads),
    "--prefix", shQuote(out_prefix)
  )
  
  if (!is.null(outgroup) && outgroup != "") {
    args <- c(args, "--outgroup", shQuote(outgroup))
  }
  
  system2(command = raxml_bin_path, args = args)
  return(paste0(out_prefix, ".raxml.bootstraps"))
}
