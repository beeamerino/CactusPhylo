# Package index

## Sequence Assemblies & PhylotaR Import

Functions to setup databases, pull taxonomic clusters, and download
GenBank accessions safely.

- [`assemble_ingroup_phylotar()`](https://beeamerino.github.io/CactusPhylo/reference/assemble_ingroup_phylotar.md)
  : Assemble Ingroup phylotaR Clusters
- [`assemble_outgroup_phylotar()`](https://beeamerino.github.io/CactusPhylo/reference/assemble_outgroup_phylotar.md)
  : Assemble Outgroup phylotaR Clusters
- [`fetch_genbank_metadata()`](https://beeamerino.github.io/CactusPhylo/reference/fetch_genbank_metadata.md)
  : Fetch Genbank Metadata

## Taxonomic Cleaning & Reconciliations

Check name spelling, audit duplicates, and verify records against
checklists.

- [`clean_taxonomic_names()`](https://beeamerino.github.io/CactusPhylo/reference/clean_taxonomic_names.md)
  : Reconcile and Validate Taxonomic Names
- [`integrate_and_clean_markers()`](https://beeamerino.github.io/CactusPhylo/reference/integrate_and_clean_markers.md)
  : Final Marker Integration and Taxonomic Cleaning

## Multiple Alignment, DECIPHER Cleaners, & Masking

Run system MAFFT and refine aligned nucleotides using gap-masking
procedures.

- [`run_mafft()`](https://beeamerino.github.io/CactusPhylo/reference/run_mafft.md)
  : Run MAFFT Alignment
- [`run_alignment_pipeline()`](https://beeamerino.github.io/CactusPhylo/reference/run_alignment_pipeline.md)
  : Run Complete Alignment Pipeline
- [`run_joint_realignment()`](https://beeamerino.github.io/CactusPhylo/reference/run_joint_realignment.md)
  : Run Final Joint Realignment Pipeline

## Locus Quality Control & Saturation Screening

Detect distance outliers and perform saturation regression checks.

- [`run_marker_screening()`](https://beeamerino.github.io/CactusPhylo/reference/run_marker_screening.md)
  : Run Ingroup Marker Screening Pipeline

## Concatenation and Partitioning Maps

Bind loci end-to-end to assemble a master phylogenetic matrix and export
format partitions.

- [`run_concatenation_pipeline()`](https://beeamerino.github.io/CactusPhylo/reference/run_concatenation_pipeline.md)
  : Run Concatenation Pipeline

## Phylogenetic Search & Constrained Inference

Run model testers (ModelTest-NG) and ML estimations (RAxML-NG) guided by
Newick scaffolds.

- [`preprocess_partitions()`](https://beeamerino.github.io/CactusPhylo/reference/preprocess_partitions.md)
  : Preprocess Partitions and Run Alignment Check
- [`run_modeltest_ng()`](https://beeamerino.github.io/CactusPhylo/reference/run_modeltest_ng.md)
  : Run ModelTest-NG Partition Evaluations
- [`build_constraint_scaffold()`](https://beeamerino.github.io/CactusPhylo/reference/build_constraint_scaffold.md)
  : Generate Newick Constraint Scaffold
- [`calculate_ml_tree()`](https://beeamerino.github.io/CactusPhylo/reference/calculate_ml_tree.md)
  : Execute ML Search in RAxML-NG
- [`calculate_rf_distances()`](https://beeamerino.github.io/CactusPhylo/reference/calculate_rf_distances.md)
  : Compute Robinson-Foulds Distances between Maximum-Likelihood Trees
- [`generate_bootstrap_script()`](https://beeamerino.github.io/CactusPhylo/reference/generate_bootstrap_script.md)
  : Generate Chunk Bootstrap Shell Script
- [`run_local_bootstraps()`](https://beeamerino.github.io/CactusPhylo/reference/run_local_bootstraps.md)
  : Run Bootstrap Search Locally
- [`collect_bootstraps()`](https://beeamerino.github.io/CactusPhylo/reference/collect_bootstraps.md)
  : Collect Bootstrap Trees
- [`check_bs_convergence()`](https://beeamerino.github.io/CactusPhylo/reference/check_bs_convergence.md)
  : Check Bootstrap Convergence
- [`calculate_temporal_bootstraps()`](https://beeamerino.github.io/CactusPhylo/reference/calculate_temporal_bootstraps.md)
  : Compute Temporal Best Maximum-Likelihood Tree Constrained Bootstrap
  Replicates
- [`map_branch_supports()`](https://beeamerino.github.io/CactusPhylo/reference/map_branch_supports.md)
  : Calculate and Burn Branch Supports

## Chronological Dating & treePL Automation

Automated treePL cross-validation and chronological calibrations over
bootstrap cohorts.

- [`rescale_tree()`](https://beeamerino.github.io/CactusPhylo/reference/rescale_tree.md)
  : Rescale all branches of a tree
- [`run_treePL()`](https://beeamerino.github.io/CactusPhylo/reference/run_treePL.md)
  : Run treePL via Wrapper
- [`run_treePL_direct()`](https://beeamerino.github.io/CactusPhylo/reference/run_treePL_direct.md)
  : Run treePL directly
- [`automate_treePL()`](https://beeamerino.github.io/CactusPhylo/reference/automate_treePL.md)
  : Automate treePL bootstrap pipeline

## Multi-Scale Topologies Validation

Compare comparative tree structures using Robinson-Foulds, DPI, and
project into 2D MDS scopes.

- [`validate_phylogenies()`](https://beeamerino.github.io/CactusPhylo/reference/validate_phylogenies.md)
  : Comparative Tree space validation pipeline

## Manuscript Figures & Publication Polish

Integrate final results, apply editorial clade collapses, and draw
SVG/PDF panels.

- [`integrate_publication_tree()`](https://beeamerino.github.io/CactusPhylo/reference/integrate_publication_tree.md)
  : Render Final Publication Figures and Registry

## IUCN Conservation Metadata

Extract threat metrics and habitats using rredlist and map color scales
for plotting.

- [`get_iucn_data()`](https://beeamerino.github.io/CactusPhylo/reference/get_iucn_data.md)
  : Extract IUCN Data from rredlist
- [`scale_fill_iucn()`](https://beeamerino.github.io/CactusPhylo/reference/scale_fill_iucn.md)
  : IUCN Category Color Scale for ggplot2

## Internal Tools and Visualization Helpers

Internal functions for phylogenetic visualization and data preparation.

- [`add_clade_labels_by_level()`](https://beeamerino.github.io/CactusPhylo/reference/add_clade_labels_by_level.md)
  : Add clade labels by level
- [`apply_clade_label_layers()`](https://beeamerino.github.io/CactusPhylo/reference/apply_clade_label_layers.md)
  : Apply clade label layers
- [`assert_constraint_columns()`](https://beeamerino.github.io/CactusPhylo/reference/assert_constraint_columns.md)
  : Assert constraint columns
- [`augment_treedata_with_registry()`](https://beeamerino.github.io/CactusPhylo/reference/augment_treedata_with_registry.md)
  : Augment treedata with registry annotations
- [`build_annotation_registry()`](https://beeamerino.github.io/CactusPhylo/reference/build_annotation_registry.md)
  : Build annotation registry
- [`compute_group_nodes()`](https://beeamerino.github.io/CactusPhylo/reference/compute_group_nodes.md)
  : Compute group nodes
- [`get_annotation_nodes()`](https://beeamerino.github.io/CactusPhylo/reference/get_annotation_nodes.md)
  : Get annotation nodes
- [`prepare_tip_annotation()`](https://beeamerino.github.io/CactusPhylo/reference/prepare_tip_annotation.md)
  : Prepare tip annotation
- [`standardize_taxon()`](https://beeamerino.github.io/CactusPhylo/reference/standardize_taxon.md)
  : Standardization helper
- [`get_tree_max_depth()`](https://beeamerino.github.io/CactusPhylo/reference/get_tree_max_depth.md)
  : Get tree max depth
- [`format_age_labels()`](https://beeamerino.github.io/CactusPhylo/reference/format_age_labels.md)
  : Format age labels
- [`add_chronogram_axis()`](https://beeamerino.github.io/CactusPhylo/reference/add_chronogram_axis.md)
  : Add chronogram axis
