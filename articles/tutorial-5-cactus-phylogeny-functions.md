# Tutorial 5: Function Reference & Dictionary

## Function Map Reference

The `CactusPhylo` library contains a comprehensive suite of functions
integrating sequence assembly, rigorous alignment quality control,
substitution model evaluation, and phylogenetic inference. Below is a
reference dictionary detailing the scientific objective and
methodological application of each function.

### Sequence Assembly & Mining

- `assemble_ingroup_phylotar(wd_path, target_genes_file, genes_map_file, min_species, force_download)`
  - **Description:** Addresses the biological problem of retrieving
    homologous sequences for a focal ingroup (e.g., **Cactaceae**;
    Guerrero, P. C., Majure, L. C., Cornejo-Romero, A., &
    Hernández-Hernández, T. (2019). Phylogenetic Relationships and
    Evolutionary Trends in the Cactus Family. Journal of Heredity,
    110(1), 4–21. <https://doi.org/10.1093/jhered/esy064>). It queries
    GenBank via `phylotaR`, applies strict taxonomic filters, evaluates
    cluster occupancy, and extracts homologous sets while mitigating
    nomenclature inconsistencies.
- `assemble_outgroup_phylotar(wd_path, target_genes_file, genes_map_file, outgroups, force_download)`
  - **Description:** Retrieves homologous sequences for specified
    outgroup lineages to ensure accurate phylogenetic rooting. By
    applying the same marker constraints as the ingroup, this function
    guarantees structural compatibility across the resulting matrices.

### Alignments & Error Modeling

- `run_alignment_pipeline(input_folder, output_dir, min_non_gap_fraction, max_missing_fraction)`
  - **Description:** Establishes hypotheses of positional homology by
    generating multiple sequence alignments (`MAFFT`; Katoh, K., &
    Standley, D. M. (2013). MAFFT multiple sequence alignment software
    version 7: Improvements in performance and usability. Molecular
    Biology and Evolution, 30(4), 772–780.
    <https://doi.org/10.1093/molbev/mst010>). It objectively mitigates
    systematic errors by identifying and masking non-homologous
    segments, ambiguously aligned regions, and extended indels
    (`DECIPHER`), ensuring a mathematically stable foundation for
    likelihood inference.
- `run_marker_screening(fasta_folder, out_base, min_cols_to_evaluate, min_aln_len_to_retain, min_nseq_to_retain, saturation_keep_cutoff)`
  - **Description:** Evaluates the phylogenetic informativeness of
    individual markers. It identifies and removes loci exhibiting high
    substitution saturation or severe length anomalies, which could
    otherwise confound downstream branch length estimation and
    topological inference.

### Integration & Curation

- `integrate_and_clean_markers(ingroup_dir, outgroup_dir, output_dir, accepted_list_file, metadata_in_file, metadata_out_file)`
  - **Description:** Reconciles the heterogeneous taxonomic metadata
    retrieved from GenBank against a curated list of accepted binomials.
    It resolves synonymies, merges ingroup and outgroup matrices, and
    guarantees nomenclatural stability across the dataset.
- `run_joint_realignment(input_dir, output_fasta_dir, output_aln_dir)`
  - **Description:** Performs a secondary multiple sequence alignment on
    the integrated ingroup and outgroup datasets to enforce positional
    homology following sequence aggregation.
- `run_concatenation_pipeline(input_dir, output_dir)`
  - **Description:** Assembles individual locus alignments into a
    unified concatenated supermatrix. It generates partition coordinate
    maps necessary for specifying independent substitution models across
    distinct genomic regions.

### IUCN Utilities

- `get_iucn_data(sp_name)`
  - **Description:** Resolves nested taxonomic mapping by interacting
    directly with the `rredlist` API. It retrieves verified
    macroevolutionary conservation categories, population trends, and
    habitat descriptions to enrich downstream biological
    interpretations.
- `scale_fill_iucn(...)`
  - **Description:** A `ggplot2` scale designed to standardize visual
    mapping of IUCN conservation threat categories across all derived
    phylogenetic figures.

### Inference & Validation

- `preprocess_partitions(phy_matrix, part_file, raxml_path)`
  - **Description:** Validates structural integrity and syntax of the
    supermatrix and its corresponding partition definitions prior to
    likelihood evaluation, preventing computational errors during
    exhaustive tree searches.
- `run_modeltest_ng(modeltest_exec_path, aln_file, part_file, prefix, threads)`
  - **Description:** Identifies the optimal substitution model for each
    predefined partition (`ModelTest-NG`; Darriba, D. et al. (2020).
    ModelTest-NG: a new and scalable tool for the selection of DNA and
    protein evolutionary models. Molecular Biology and Evolution, 37(1),
    291-294. doi.org/10.1093/molbev/msz189). By selecting models based
    on the AICc criterion (Hurvich and Tsai, 1989), it statistically
    controls for mutational heterogeneity and minimizes systematic bias
    during inference.
- `build_constraint_scaffold(alignment_path, constraints_csv_path)`
  - **Description:** Synthesizes a multifurcating topological backbone
    that enforces known higher-level monophyletic relationships during
    the maximum-likelihood search.
- `calculate_ml_tree(raxml_bin_path, aln_file, part_file, constraint_file, threads)`
  - **Description:** Infers the maximum-likelihood evolutionary
    hypothesis that best explains the observed supermatrix data under
    the established substitution models and topological constraints.
- `write_treePL_calibration_cfg(...)` and
  `run_treePL_cv(tree_path, cfg_file, cv_out_path)`
  - **Description:** Integrates branch length data with fossil/secondary
    temporal constraints to estimate an ultrametric chronogram
    (`treePL`; Smith, S. A., & O’Meara, B. C. (2012). TreePL: Divergence
    time estimation using penalized likelihood for large phylogenies.
    Bioinformatics, 28(20), 2689–2690.
    <https://doi.org/10.1093/bioinformatics/bts492>). Iterational
    cross-validation determines the optimal smoothing parameter to
    accommodate rate heterogeneity across lineages using penalized
    likelihood (Sanderson, 2002).
- `validate_phylogenies(...)`
  - **Description:** Quantifies topological congruence between the
    inferred evolutionary hypotheses and external reference backbones
    using Robinson-Foulds distances and Non-Metric Multidimensional
    Scaling (NMDS).
- `integrate_publication_tree(ml_support_tree_path, summary_chronogram_path, constraints_path, out_dir, collapse_cutoff)`
  - **Description:** Maps statistical support values (e.g., TBE) across
    nodes of the final chronogram. It systematically polytomizes clades
    lacking sufficient statistical robustness (e.g., Support \< 70),
    producing a conservative and scientifically defensible visualization
    of the evolutionary history.
