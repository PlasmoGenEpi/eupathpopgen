process PER_LOCUS_POPGEN_SUMMARY {
    tag "${prefix}"
    label 'process_single'

    conda "${moduleDir}/environment.yml"
    container "${ workflow.containerEngine in ['singularity', 'apptainer'] && !task.ext.singularity_pull_docker_container ?
        'https://community-cr-prod.seqera.io/docker/registry/v2/blobs/sha256/5d/5df2d19a284254d5dfef5af0be373b8e3a7f9c6c321eb55bafe052cf3078b0a8/data' :
        'community.wave.seqera.io/library/r-base_r-pgecore_r-ape_r-pegas_pruned:11fa33536a326326' }"

    input:
    path allele_table

    output:
    tuple val(prefix), path("${prefix}.per_locus_popgen_summary.tsv"), emit: per_locus_popgen_summary
    path "versions.yml", emit: versions

    script:
    prefix = allele_table.getBaseName(3)
    """
    if ! command -v muscle >/dev/null 2>&1; then
        echo "ERROR: muscle binary not found on PATH (needed by per_locus_popgen_summary)." >&2
        exit 1
    fi

    # bioconductor-msa is missing from the osx-arm64 conda env; install it into ./r_libs if absent.
    Rscript -e '
      libs <- file.path(getwd(), "r_libs")
      dir.create(libs, recursive = TRUE, showWarnings = FALSE)
      .libPaths(c(libs, .libPaths()))
      if (!requireNamespace("msa", quietly = TRUE)) {
        BiocManager::install("msa", lib = libs, ask = FALSE, update = FALSE, type = "both")
        if (!requireNamespace("msa", quietly = TRUE)) stop("Failed to install Bioconductor package msa")
      }
    '

    export R_LIBS_USER="\$PWD/r_libs"
    export PATH="\$(Rscript -e 'cat(system.file("exec", package = "PGEcore"))'):\${PATH}"
    per_locus_popgen_summary \\
        --allele_table ${allele_table} \\
        --output ${prefix}.per_locus_popgen_summary.tsv

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        r-base: \$(R --version | sed -n '1s/.*version \\([0-9.]*\\).*/\\1/p')
        PGEcore: \$(Rscript -e 'cat(as.character(packageVersion("PGEcore")))' 2>/dev/null || echo 'NA')
        pegas: \$(Rscript -e 'cat(as.character(packageVersion("pegas")))' 2>/dev/null || echo 'NA')
        msa: \$(R_LIBS_USER=\$PWD/r_libs Rscript -e 'cat(as.character(packageVersion("msa")))' 2>/dev/null || echo 'NA')
        muscle: \$(muscle -version 2>&1 | head -n 1 || echo 'NA')
    END_VERSIONS
    """
}
