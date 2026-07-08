#' Rescale all branches of a tree
#' @param tree phylo. 
#' @param factor numeric.
#' @return phylo
#' @export
rescale_tree <- function(tree, factor = 100){
  cat("Rescaling all branches by factor:", factor, "\n")
  tree$edge.length <- tree$edge.length * factor
  return(tree)
}

#' Run treePL via Wrapper
#'
#' Cites the reference treePL wrapper: https://github.com/tongjial/treepl_wrapper
#'
#' @param cfg Character. Configuration file.
#' @param treefile Character. Tree file.
#' @param label Character. Label for the run.
#' @param wrapper_sh Character. Path to the treepl wrapper shell script.
#' @export
run_treePL <- function(cfg, treefile, label, wrapper_sh){
  cmd <- paste("bash", shQuote(wrapper_sh), shQuote(cfg), shQuote(treefile), shQuote(label))
  cat("Running treePL wrapper for:", label, "\n")
  system(cmd)
  cat("Finished:", label, "\n\n")
}

#' Run treePL directly
#'
#' @param cfg_file Character. Configuration file.
#' @param label Character. Label.
#' @param cwd Character. Working directory.
#' @export
run_treePL_direct <- function(cfg_file, label, cwd = NULL){
  if(!is.null(cwd)) oldwd <- getwd() else oldwd <- NULL
  if(!is.null(cwd)) setwd(cwd)
  
  cmd <- paste("treePL", shQuote(cfg_file))
  cat(Sys.time(), "- Running treePL (direct) for:", label, "\n")
  system(cmd)
  cat(Sys.time(), "- Finished:", label, "\n\n")
  
  if(!is.null(oldwd)) setwd(oldwd)
}

#' Automate treePL bootstrap pipeline
#'
#' @param cfg_file Character. Configuration file.
#' @param wrapper_sh Character. Wrapper script path.
#' @param ml_tree_file Character. Path to the maximum-likelihood tree.
#' @param bs_trees_file Character. Bootstraps tree path.
#' @param results_dir Character. Results output dir.
#' @param treePL_out Character. Output treePL directory.
#' @param num_bs Integer or NULL. Number of bootstrap trees to use. If NULL, uses all available.
#' @export
automate_treePL <- function(cfg_file, wrapper_sh, ml_tree_file, bs_trees_file, results_dir, treePL_out, num_bs = NULL) {
  
  # Convert inputs to absolute paths so they survive setwd()
  cfg_file_abs <- normalizePath(cfg_file, mustWork = TRUE)
  wrapper_sh_abs <- normalizePath(wrapper_sh, mustWork = TRUE)
  
  ml_dir       <- file.path(results_dir, "ML_tree")
  bs_out_dir   <- file.path(results_dir, "BS_tree")
  
  dir.create(results_dir, recursive = TRUE, showWarnings = FALSE)
  dir.create(ml_dir, recursive = TRUE, showWarnings = FALSE)
  dir.create(bs_out_dir, recursive = TRUE, showWarnings = FALSE)
  dir.create(treePL_out, recursive = TRUE, showWarnings = FALSE)
  
  # STEP 0: Fix and rescale maximum-likelihood tree
  ml_tree <- ape::read.tree(ml_tree_file)
  
  # Root the maximum-likelihood tree using Portulaca_fulgens as outgroup if unrooted
  if (!ape::is.rooted(ml_tree) && "Portulaca_fulgens" %in% ml_tree$tip.label) {
    if (requireNamespace("phytools", quietly = TRUE)) {
      ml_tree <- phytools::reroot(ml_tree, node.number = which(ml_tree$tip.label == "Portulaca_fulgens"))
    } else {
      ml_tree <- ape::root(ml_tree, outgroup = "Portulaca_fulgens", resolve.root = TRUE)
    }
  }
  
  ml_tree <- rescale_tree(ml_tree)
  ml_tree_fixed_file <- file.path(ml_dir, "supportTree_raxml-ng_fixed.tree")
  ape::write.tree(ml_tree, ml_tree_fixed_file)
  ml_tree_fixed_file_abs <- normalizePath(ml_tree_fixed_file, mustWork = TRUE)
  
  # STEP 1: Run treePL on maximum-likelihood tree (priming and cross-validation)
  if (!file.exists(file.path(ml_dir, "treepl_ML_tree.tre"))) {
    oldwd <- getwd()
    setwd(ml_dir)
    run_treePL(cfg_file_abs, ml_tree_fixed_file_abs, "ML_tree", wrapper_sh = wrapper_sh_abs)
    setwd(oldwd)
  } else {
    cat("treePL results for the maximum-likelihood tree already exist! Skipping treePL run.\n")
  }

  # STEP 2/3: Extract optimization parameters and smoothing from maximum-likelihood tree
  cfg_smooth_file <- file.path(ml_dir, "configure_smooth_ML_tree")
  cfg_lines <- readLines(cfg_smooth_file)
  opt_lines   <- grep("^opt =", cfg_lines, value = TRUE)
  optad_lines <- grep("^optad", cfg_lines, value = TRUE)
  
  # The wrapper has already calculated the best smoothing and appended it.
  smoothing_line <- grep("^smoothing =", cfg_lines, value = TRUE)
  if (length(smoothing_line) > 0) {
    best_smoothing <- as.numeric(sub(".*=\\s*", "", smoothing_line[length(smoothing_line)]))
  } else {
    # Fallback to manual extraction if smoothing line is missing
    cv_file <- file.path(ml_dir, "cv_ML_tree")
    if (file.exists(cv_file)) {
      cv_raw <- readLines(cv_file)
      smooth_raw <- regmatches(cv_raw, regexpr("\\([0-9.eE+-]+\\)", cv_raw))
      smoothing <- as.numeric(gsub("[()]", "", smooth_raw))
      chisq <- as.numeric(sub(".*\\)\\s+", "", cv_raw))
      cv_data <- data.frame(smoothing = smoothing, chisq = chisq)
      if (nrow(cv_data) > 0) {
        best_smoothing <- cv_data$smoothing[which.min(cv_data$chisq)]
      }
    }
  }
  cat("Best smoothing strategy chosen:", best_smoothing, "\n")
  
  # STEP 4: Prepare and rescale Bootstrap Trees (from concatenated)
  bs_all <- ape::read.tree(bs_trees_file)
  message(length(bs_all), " BS trees found in concatenated file\n")
  
  if (is.null(num_bs)) {
    num_bs_to_use <- length(bs_all)
  } else {
    num_bs_to_use <- min(num_bs, length(bs_all))
  }
  
  set.seed(2025)
  bs_subset <- sample(bs_all, num_bs_to_use)
  
  # Extract numsites from the original config, default to 12700 if missing
  numsites_line <- grep("^numsites", readLines(cfg_file_abs), value = TRUE)
  if (length(numsites_line) == 0) numsites_line <- "numsites = 12700"
  
  for(i in seq_along(bs_subset)){
    label <- paste0("BS_", i)
    
    bs_folder <- file.path(bs_out_dir, label)
    dir.create(bs_folder, recursive = TRUE, showWarnings = FALSE)
    
    # Skip processing if tree PL output already exists
    if (file.exists(file.path(bs_folder, paste0("treepl_", label, ".tre")))) {
      cat("Skipping BS tree preparation:", label, "- already completed\n")
      next
    }
    
    cat("Processing BS tree:", label, "\n")
    
    # Root the BS tree using Portulaca_fulgens as outgroup if unrooted
    if (!ape::is.rooted(bs_subset[[i]]) && "Portulaca_fulgens" %in% bs_subset[[i]]$tip.label) {
      if (requireNamespace("phytools", quietly = TRUE)) {
        bs_subset[[i]] <- phytools::reroot(bs_subset[[i]], node.number = which(bs_subset[[i]]$tip.label == "Portulaca_fulgens"))
      } else {
        bs_subset[[i]] <- ape::root(bs_subset[[i]], outgroup = "Portulaca_fulgens", resolve.root = TRUE)
      }
    }
    
    tree <- rescale_tree(bs_subset[[i]])
    tree_fixed_file <- file.path(bs_folder, paste0(label, "_fixed.tree"))
    ape::write.tree(tree, tree_fixed_file)
    tree_fixed_file_abs <- normalizePath(tree_fixed_file, mustWork = TRUE)
    
    bs_cfg_file <- file.path(bs_folder, paste0("cfg_", label, ".cfg"))
    cfg_content <- c(
      paste0("treefile = ", tree_fixed_file_abs),
      numsites_line[1],
      grep("^mrca|^min|^max", readLines(cfg_file_abs), value = TRUE),
      "nthreads = 8",
      "thorough",
      opt_lines,
      optad_lines,
      paste0("smoothing = ", best_smoothing),
      paste0("outfile = treepl_", label, ".tre")
    )
    writeLines(cfg_content, bs_cfg_file)
  }
  
  # STEP 5: Execute treePL for each bootstrap tree
  bs_folders <- list.dirs(bs_out_dir, recursive = FALSE)
  for(bs_folder in bs_folders){
    label <- basename(bs_folder)
    out_tree <- file.path(bs_folder, paste0("treepl_", label, ".tre"))
    if (file.exists(out_tree)) {
       message("Skipping ", label, " execution - already exists")
       next
    }
    
    bs_cfg <- list.files(bs_folder, pattern="^cfg_.*\\.cfg$", full.names = TRUE)
    if(length(bs_cfg) == 1){
      label <- basename(bs_folder)
      bs_cfg_abs <- normalizePath(bs_cfg, mustWork = TRUE)
      run_treePL_direct(bs_cfg_abs, label, cwd = bs_folder)
      message("Bootstrap treePL completed. Results in:", bs_folder, "\n")
    } else {
      message("Skipping", bs_folder, "- CFG missing\n")
    }
  }
  
  # STEP 6: Collect treePL outputs
  ml_results_dir <- file.path(results_dir, "ML_tree_treePL")
  bs_results_dir <- file.path(results_dir, "BS_tree_treePL")
  
  dir.create(ml_results_dir, recursive = TRUE, showWarnings = FALSE)
  dir.create(bs_results_dir, recursive = TRUE, showWarnings = FALSE)
  
  ml_treepl_file <- list.files(ml_dir, pattern = "^treepl_.*\\.tre$", full.names = TRUE)
  if(length(ml_treepl_file) == 1){
    file.copy(ml_treepl_file, ml_results_dir, overwrite = TRUE)
    message(Sys.time(), " - treePL chronogram for maximum-likelihood tree copied to: ", ml_results_dir)
  }
  
  bs_folders <- list.dirs(bs_out_dir, recursive = FALSE)
  for(bs_folder in bs_folders){
    bs_treepl <- list.files(bs_folder, pattern = "^treepl_.*\\.tre$", full.names = TRUE)
    if(length(bs_treepl) == 1){
      file.copy(bs_treepl, bs_results_dir, overwrite = TRUE)
      message(Sys.time(), " - bootstrap treePL tree copied: ", basename(bs_treepl))
    }
  }
  
  bs_treepl_files <- list.files(
    bs_out_dir,
    pattern = "^treepl_.*\\.tre$",
    recursive = TRUE,
    full.names = TRUE
  )
  
  out_bs_all <- file.path(treePL_out, "bsTree_treePL.tree")
  file.create(out_bs_all)
  
  for(f in bs_treepl_files){
    cat(readLines(f), file = out_bs_all, sep = "\n", append = TRUE)
  }
  
  ml_treepl_file <- file.path(ml_dir, "treepl_ML_tree.tre")
  if (file.exists(ml_treepl_file)) {
    file.copy(
      ml_treepl_file,
      file.path(treePL_out, "BestTree_treePL.tree"),
      overwrite = TRUE
    )
  }
}


