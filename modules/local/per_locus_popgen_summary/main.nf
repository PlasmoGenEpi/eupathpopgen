process PER_LOCUS_POPGEN_SUMMARY {
    tag "${allele_table.simpleName}"
    label 'process_single'
    label 'pgecore'

    // nf-core docker runs as -u uid:gid; override so we can apt-get muscle
    containerOptions = { workflow.containerEngine == 'docker' ? '--user root' : '' }

    conda "${moduleDir}/environment.yml"
    container "${ workflow.containerEngine in ['singularity', 'apptainer'] && !task.ext.singularity_pull_docker_container ?
        'https://community-cr-prod.seqera.io/docker/registry/v2/blobs/sha256/b8/b8b5976e182bb3b8f3b3073fe7ccb663bfa240ef8476d59faf2cccf8b180fe6f/data' :
        'docker.io/bioconductor/bioconductor_docker:RELEASE_3_20' }"

    input:
    path allele_table

    output:
    path "per_locus_popgen_summary.tsv", emit: per_locus_popgen_summary
    path "versions.yml",                 emit: versions

    script:
    """
    # Preserve host ownership of the work dir (Nextflow created it as the launching user)
    if [ "\$(id -u)" = "0" ]; then
        HOST_OWNER="\$(stat -c '%u:%g' . 2>/dev/null || stat -f '%u:%g' .)"
    fi

    # muscle is required by msa(); bioconductor image has build libs but not muscle
    if command -v apt-get >/dev/null 2>&1 && [ "\$(id -u)" = "0" ] && ! command -v muscle >/dev/null 2>&1; then
        apt-get update -qq
        DEBIAN_FRONTEND=noninteractive apt-get install -y -qq --no-install-recommends muscle >/dev/null
        rm -rf /var/lib/apt/lists/*
    fi

    if ! command -v muscle >/dev/null 2>&1; then
        echo "ERROR: muscle binary not found on PATH (needed by per_locus_popgen_summary)." >&2
        exit 1
    fi

    Rscript ${projectDir}/bin/ensure_pgecore.R ${params.pgecore_git_repo} ${params.pgecore_git_ref}

    # Install Suggests into ./r_libs when missing.
    # Prefer BiocManager binaries (needed on osx-arm64 where bioconda lacks msa).
    Rscript -e '
      libs <- file.path(getwd(), "r_libs")
      dir.create(libs, recursive = TRUE, showWarnings = FALSE)
      .libPaths(c(libs, .libPaths()))
      Sys.setenv(R_LIBS_USER = libs)
      if (!requireNamespace("BiocManager", quietly = TRUE)) {
        install.packages("BiocManager", lib = libs, repos = "https://cloud.r-project.org")
      }
      pkgs <- c("Biostrings", "msa", "pwalign", "pegas", "ape")
      missing <- pkgs[!vapply(pkgs, requireNamespace, logical(1), quietly = TRUE)]
      if (length(missing)) {
        BiocManager::install(missing, lib = libs, ask = FALSE, update = FALSE, type = "both")
      }
      still_missing <- missing[!vapply(missing, requireNamespace, logical(1), quietly = TRUE)]
      if (length(still_missing)) {
        stop("Failed to install required packages: ", paste(still_missing, collapse = ", "))
      }
    '

    ${projectDir}/bin/pgecore_cli.sh per_locus_popgen_summary \\
        --allele_table ${allele_table} \\
        --output per_locus_popgen_summary.tsv

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        r-base: \$(R --version | sed -n '1s/.*version \\([0-9.]*\\).*/\\1/p')
        PGEcore: \$(R_LIBS_USER=\$PWD/r_libs Rscript -e 'cat(as.character(packageVersion("PGEcore")))' 2>/dev/null || echo 'NA')
        pegas: \$(R_LIBS_USER=\$PWD/r_libs Rscript -e 'cat(as.character(packageVersion("pegas")))' 2>/dev/null || echo 'NA')
        muscle: \$(muscle -version 2>&1 | head -n 1 || echo 'NA')
    END_VERSIONS

    # Return ownership so host cleanup / -resume stays writable
    if [ "\$(id -u)" = "0" ] && [ -n "\${HOST_OWNER:-}" ]; then
        chown -R "\${HOST_OWNER}" .
    fi
    """
}
