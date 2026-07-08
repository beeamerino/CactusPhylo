#' Standardization helper
#' @export
#' @keywords internal
standardize_taxon <- function(x) {
  stringr::str_replace_all(x, "[[:space:]-]+", "_") |>
    stringr::str_replace_all("_+", "_") |>
    stringr::str_replace_all("^_|_$", "")
}

#' Assert constraint columns
#' @export
#' @keywords internal
assert_constraint_columns <- function(constraints_tbl) {
  required_constraint_cols <- c(
    "Genus", "Specie_name", "Clade", "Subfam", "Family",
    "Annot_level_1", "Annot_level_2", "Annot_level_3", "Annot_level_4"
  )
  miss <- setdiff(required_constraint_cols, names(constraints_tbl))
  if (length(miss)) {
    stop(
      "constraints_tbl is missing required columns: ",
      paste(miss, collapse = ", "),
      call. = FALSE
    )
  }
  invisible(TRUE)
}

#' Prepare tip annotation
#' @export
#' @keywords internal
prepare_tip_annotation <- function(tree, constraints_tbl) {
  if (is.null(tree)) stop("tree is NULL", call. = FALSE)
  if (is.null(constraints_tbl)) stop("constraints_tbl is NULL", call. = FALSE)
  
  assert_constraint_columns(constraints_tbl)
  
  tbl <- constraints_tbl |>
    dplyr::mutate(
      Specie_name = standardize_taxon(Specie_name),
      tip_label = Specie_name
    ) |>
    dplyr::distinct(tip_label, .keep_all = TRUE)
  
  matched <- tbl |> dplyr::filter(tip_label %in% tree$tip.label)
  
  if (!nrow(matched)) {
    stop("No rows from constraints_tbl matched tree$tip.label", call. = FALSE)
  }
  
  matched
}

#' Compute group nodes
#' @export
#' @keywords internal
compute_group_nodes <- function(tree, tip_tbl, group_col, group_values = NULL, min_tips = 2L) {
  if (!group_col %in% names(tip_tbl)) {
    stop("group_col not found in tip_tbl: ", group_col, call. = FALSE)
  }
  
  tbl <- tip_tbl |>
    dplyr::filter(!is.na(.data[[group_col]]), .data[[group_col]] != "")
  
  if (!is.null(group_values)) {
    tbl <- tbl |> dplyr::filter(.data[[group_col]] %in% group_values)
  }
  
  if (!nrow(tbl)) {
    return(tibble::tibble(
      group_col = character(),
      label = character(),
      n_tips_target = integer(),
      n_tips_desc = integer(),
      node = integer(),
      monophyletic = logical(),
      reason = character()
    ))
  }
  
  groups <- split(tbl$tip_label, tbl[[group_col]])
  
  purrr::imap_dfr(groups, function(tips, grp) {
    tips <- sort(unique(tips))
    n_tips_target <- length(tips)
    
    if (n_tips_target < min_tips) {
      return(tibble::tibble(
        group_col = group_col,
        label = grp,
        n_tips_target = n_tips_target,
        n_tips_desc = NA_integer_,
        node = NA_integer_,
        monophyletic = FALSE,
        reason = paste0("fewer than ", min_tips, " matching tips")
      ))
    }
    
    if (n_tips_target == 1L) {
      node <- match(tips[1], tree$tip.label)
      mono <- TRUE
      desc_tips <- tips
      n_tips_desc <- 1L
    } else {
      node <- suppressWarnings(ape::getMRCA(tree, tips))
      if (length(node) == 0 || is.null(node) || is.na(node)) {
        return(tibble::tibble(
          group_col = group_col,
          label = grp,
          n_tips_target = n_tips_target,
          n_tips_desc = NA_integer_,
          node = NA_integer_,
          monophyletic = FALSE,
          reason = "getMRCA returned NA"
        ))
      }
      desc_tips <- sort(unique(ape::extract.clade(tree, node)$tip.label))
      n_tips_desc <- length(desc_tips)
      mono <- identical(desc_tips, tips)
    }

    tibble::tibble(
      group_col = group_col,
      label = grp,
      n_tips_target = n_tips_target,
      n_tips_desc = n_tips_desc,
      node = as.integer(node),
      monophyletic = mono,
      reason = ifelse(mono, NA_character_, "MRCA descendants do not equal target tip set")
    )
  })
}

#' Get annotation nodes
#' @export
#' @keywords internal
get_annotation_nodes <- function(tree,
                                 constraints_tbl,
                                 group_col,
                                 group_values = NULL,
                                 min_tips = 2L,
                                 require_monophyly = TRUE) {
  tip_tbl <- prepare_tip_annotation(tree, constraints_tbl)
  
  out <- compute_group_nodes(
    tree = tree,
    tip_tbl = tip_tbl,
    group_col = group_col,
    group_values = group_values,
    min_tips = min_tips
  )
  
  if (require_monophyly) {
    out <- out |> dplyr::filter(monophyletic)
  }
  
  out
}

#' Build annotation registry
#' @export
#' @keywords internal
build_annotation_registry <- function(tree, constraints_tbl,
                                      main_level4_values = NULL,
                                      supp_level4_min_tips = 10L,
                                      require_monophyly = TRUE) {
  tip_tbl <- prepare_tip_annotation(tree, constraints_tbl)
  
  level_keys <- paste0("Annot_level_", 1:3)
  
  level_nodes <- purrr::set_names(
    purrr::map(level_keys, function(col) {
      get_annotation_nodes(
        tree = tree,
        constraints_tbl = constraints_tbl,
        group_col = col,
        min_tips = 2L,
        require_monophyly = require_monophyly
      )
    }),
    nm = paste0("level_", 1:3)
  )
  
  failed_levels <- purrr::set_names(
    purrr::map(2:4, function(i) {
      compute_group_nodes(
        tree = tree,
        tip_tbl = tip_tbl,
        group_col = paste0("Annot_level_", i),
        min_tips = 2L
      ) |> dplyr::filter(!monophyletic | is.na(node))
    }),
    nm = paste0("failed_level_", 2:4)
  )
  
  c(
    level_nodes,
    list(
      level_4_main = get_annotation_nodes(
        tree = tree,
        constraints_tbl = constraints_tbl,
        group_col = "Annot_level_4",
        group_values = main_level4_values,
        min_tips = 2L,
        require_monophyly = require_monophyly
      ),
      level_4_supp = get_annotation_nodes(
        tree = tree,
        constraints_tbl = constraints_tbl,
        group_col = "Annot_level_4",
        group_values = NULL,
        min_tips = supp_level4_min_tips,
        require_monophyly = require_monophyly
      )
    ),
    failed_levels
  )
}

#' Augment treedata with registry annotations
#' @param treedata_obj A treedata object
#' @param registry A registry data frame
#' @export
augment_treedata_with_registry <- function(treedata_obj, registry) {
  if (!inherits(treedata_obj, "treedata")) {
    if (inherits(treedata_obj, "phylo")) {
      treedata_obj <- tidytree::as.treedata(tidytree::as_tibble(treedata_obj))
    } else {
      stop("treedata_obj must be a treedata or phylo object")
    }
  }
  
  node_annotations <- purrr::map_dfr(names(registry), function(lvl) {
    df <- registry[[lvl]]
    if (is.data.frame(df) && nrow(df) > 0) {
      df |> dplyr::mutate(clade_level = lvl)
    } else {
      NULL
    }
  })
  
  if (nrow(node_annotations) > 0) {
    wide_annot <- node_annotations |>
      dplyr::select(node, label, clade_level) |>
      dplyr::filter(!is.na(node)) |>
      tidyr::pivot_wider(
        names_from = clade_level, 
        values_from = label, 
        values_fn = list(label = function(x) paste(unique(x), collapse = " | "))
      )
      
    tbl <- tidytree::as_tibble(treedata_obj) |>
      dplyr::left_join(wide_annot, by = "node")
      
    treedata_obj <- tidytree::as.treedata(tbl)
  }
  
  return(treedata_obj)
}

#' Add clade labels by level
#' @export
#' @keywords internal
add_clade_labels_by_level <- function(p,
                                      label_tbl,
                                      fontsize = 3,
                                      barsize = 0.45,
                                      offset = 0.03,
                                      offset_text = 0.004,
                                      fontface = "plain",
                                      sort_desc = TRUE,
                                      angle = 0,
                                      align = TRUE) {
  if (is.null(label_tbl) || !nrow(label_tbl)) return(p)
  
  node_pos <- p$data |>
    dplyr::select(node, x, y)
  
  plot_tbl <- label_tbl |>
    dplyr::left_join(node_pos, by = "node") |>
    dplyr::filter(!is.na(x), !is.na(y)) |>
    dplyr::distinct(node, .keep_all = TRUE)
  
  if (!nrow(plot_tbl)) return(p)
  
  if (sort_desc) {
    plot_tbl <- plot_tbl |> dplyr::arrange(dplyr::desc(y), dplyr::desc(n_tips_target), label)
  } else {
    plot_tbl <- plot_tbl |> dplyr::arrange(y, dplyr::desc(n_tips_target), label)
  }
  
  span_x <- diff(range(p$data$x, na.rm = TRUE))
  off_abs <- span_x * offset
  off_txt_abs <- span_x * offset_text
  
  for (i in seq_len(nrow(plot_tbl))) {
    p <- p +
      ggtree::geom_cladelabel(
        node = plot_tbl$node[i],
        label = plot_tbl$label[i],
        align = align,
        angle = angle,
        barsize = barsize,
        fontsize = fontsize,
        fontface = fontface,
        offset = off_abs,
        offset.text = off_txt_abs
      )
  }
  
  p
}

#' Apply clade label layers
#' @export
#' @keywords internal
apply_clade_label_layers <- function(p, registry, layer_specs) {
  if (is.null(layer_specs) || !nrow(layer_specs)) return(p)
  
  if (!"align" %in% names(layer_specs)) {
    layer_specs$align <- TRUE
  }
  
  for (i in seq_len(nrow(layer_specs))) {
    reg_name <- layer_specs$reg_name[i]
    if (!reg_name %in% names(registry)) next
    
    p <- add_clade_labels_by_level(
      p = p,
      label_tbl = registry[[reg_name]],
      fontsize = layer_specs$fontsize[i],
      barsize = layer_specs$barsize[i],
      offset = layer_specs$offset[i],
      offset_text = layer_specs$offset_text[i],
      fontface = layer_specs$fontface[i],
      sort_desc = layer_specs$sort_desc[i],
      angle = layer_specs$angle[i],
      align = layer_specs$align[i]
    )
  }
  
  p
}

#' Get tree max depth
#' @export
#' @keywords internal
get_tree_max_depth <- function(tree) {
  tip_depths <- ape::node.depth.edgelength(tree)[seq_len(ape::Ntip(tree))]
  max(tip_depths, na.rm = TRUE)
}

#' Format age labels
#' @export
#' @keywords internal
format_age_labels <- function(x, digits = 1L) {
  out <- format(round(x, digits), nsmall = ifelse(digits > 0, digits, 0), trim = TRUE)
  out[sub("\\.0+$", "", out) == "0"] <- "0"
  sub("\\.0+$", "", out)
}

#' Add chronogram axis
#' @export
#' @keywords internal
add_chronogram_axis <- function(p, tree, by = 5, digits = 0L,
                                axis_offset_frac = 0.052,
                                tick_height_frac = 0.010,
                                label_offset_frac = 0.028,
                                title_margin_top = 28, bar_size = 12,
                                segment_size = 2.5) {
  tree_max <- get_tree_max_depth(tree)
  
  max_floor <- floor(tree_max / by) * by
  age_breaks <- seq(from = max_floor, to = 0, by = -by)
  
  x_breaks <- tree_max - age_breaks
  
  y_min <- min(p$data$y, na.rm = TRUE)
  y_max <- max(p$data$y, na.rm = TRUE)
  span_y <- y_max - y_min
  
  axis_y    <- y_min - span_y * axis_offset_frac
  tick_low  <- axis_y
  tick_high <- axis_y + span_y * tick_height_frac
  label_y   <- axis_y - span_y * label_offset_frac
  
  axis_tbl <- tibble::tibble(
    x = x_breaks,
    label = format_age_labels(age_breaks, digits = digits)
  )
  
  p +
    ggplot2::scale_x_continuous(
      breaks = x_breaks,
      labels = NULL,
      expand = ggplot2::expansion(mult = c(0, 0), add = c(0, 0))
    ) +
    ggplot2::labs(x = "Time before present (Ma)", y = NULL) +
    ggplot2::theme(
      axis.title.x = ggplot2::element_text(
        size = bar_size,
        colour = "black",
        margin = ggplot2::margin(t = title_margin_top)
      ),
      axis.text.x = ggplot2::element_blank(),
      axis.line.x = ggplot2::element_blank(),
      axis.ticks.x = ggplot2::element_blank()
    ) +
    ggplot2::annotate(
      "segment",
      x = 0,
      xend = tree_max,
      y = axis_y,
      yend = axis_y,
      linewidth = 0.3,
      colour = "black"
    ) +
    ggplot2::geom_segment(
      data = axis_tbl,
      ggplot2::aes(x = x, xend = x, y = tick_low, yend = tick_high),
      inherit.aes = FALSE,
      linewidth = 0.3,
      colour = "black"
    ) +
    ggplot2::geom_text(
      data = axis_tbl,
      ggplot2::aes(x = x, y = label_y, label = label),
      inherit.aes = FALSE,
      size = segment_size
    )
}
