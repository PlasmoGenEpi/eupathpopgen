process RUN_MOIRE {
    tag "${allele_table.simpleName}"
    label 'process_low'
    label 'pgecore'

    conda "${moduleDir}/environment.yml"
    container "${ workflow.containerEngine in ['singularity', 'apptainer'] && !task.ext.singularity_pull_docker_container ?
        'https://community-cr-prod.seqera.io/docker/registry/v2/blobs/sha256/b8/b8b5976e182bb3b8f3b3073fe7ccb663bfa240ef8476d59faf2cccf8b180fe6f/data' :
        'docker.io/rocker/r-ver:4.4.2' }"

    input:
    path allele_table

    output:
    path "coi_summary.tsv",           emit: coi_summary
    path "he_summary.tsv",            emit: he_summary
    path "allele_freq_summary.tsv",   emit: allele_freq_summary
    path "relatedness_summary.tsv",   emit: relatedness_summary
    path "effective_coi_summary.tsv", emit: effective_coi_summary
    path "convergence_summary.tsv",   emit: convergence_summary, optional: true
    path "mcmc_results.rds",          emit: mcmc_results, optional: true
    path "versions.yml",              emit: versions

    script:
    def extra_args = task.ext.args ?: ''
    """
    Rscript ${projectDir}/bin/ensure_pgecore.R ${params.pgecore_git_repo} ${params.pgecore_git_ref}

    # MOIRE is a Suggests dependency of PGEcore; install into ./r_libs when missing.
    Rscript -e 'libs <- file.path(getwd(), "r_libs"); dir.create(libs, recursive=TRUE, showWarnings=FALSE); .libPaths(c(libs, .libPaths())); Sys.setenv(R_LIBS_USER=libs); if (!requireNamespace("moire", quietly=TRUE)) remotes::install_github("EPPIcenter/moire", lib=libs, upgrade="never")'

    ${projectDir}/bin/pgecore_cli.sh moire_wrapper \\
        --allele_table ${allele_table} \\
        --coi_output coi_summary.tsv \\
        --he_output he_summary.tsv \\
        --allele_freq_output allele_freq_summary.tsv \\
        --relatedness_output relatedness_summary.tsv \\
        --effective_coi_output effective_coi_summary.tsv \\
        --convergence_summary_output convergence_summary.tsv \\
        --threads ${task.cpus} \\
        ${extra_args}

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        r-base: \$(R --version | sed -n '1s/.*version \\([0-9.]*\\).*/\\1/p')
        PGEcore: \$(R_LIBS_USER=\$PWD/r_libs Rscript -e 'cat(as.character(packageVersion("PGEcore")))' 2>/dev/null || echo 'NA')
        moire: \$(R_LIBS_USER=\$PWD/r_libs Rscript -e 'cat(as.character(packageVersion("moire")))' 2>/dev/null || echo 'NA')
    END_VERSIONS
    """
}
