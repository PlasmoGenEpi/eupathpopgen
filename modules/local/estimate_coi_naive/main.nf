process ESTIMATE_COI_NAIVE {
    tag "${allele_table.simpleName}"
    label 'process_single'
    label 'pgecore'

    conda "${moduleDir}/environment.yml"
    container "${ workflow.containerEngine in ['singularity', 'apptainer'] && !task.ext.singularity_pull_docker_container ?
        'https://community-cr-prod.seqera.io/docker/registry/v2/blobs/sha256/b8/b8b5976e182bb3b8f3b3073fe7ccb663bfa240ef8476d59faf2cccf8b180fe6f/data' :
        'docker.io/rocker/r-ver:4.4.2' }"

    input:
    path allele_table
    val method
    val threshold

    output:
    path "coi_table.tsv", emit: coi_table
    path "versions.yml",  emit: versions

    script:
    def threshold_arg = method == "integer_method" ? "--integer_threshold ${threshold}" : "--quantile_threshold ${threshold}"
    if (!(method in ["integer_method", "quantile_method"])) {
        error("'method' must be integer_method or quantile_method. Provided: ${method}")
    }
    """
    Rscript ${projectDir}/bin/ensure_pgecore.R ${params.pgecore_git_repo} ${params.pgecore_git_ref}

    ${projectDir}/bin/pgecore_cli.sh estimate_coi_naive \\
        --allele_table ${allele_table} \\
        --output coi_table.tsv \\
        --method ${method} \\
        ${threshold_arg}

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        r-base: \$(R --version | sed -n '1s/.*version \\([0-9.]*\\).*/\\1/p')
        PGEcore: \$(R_LIBS_USER=$PWD/r_libs Rscript -e 'cat(as.character(packageVersion("PGEcore")))' 2>/dev/null || echo 'NA')
    END_VERSIONS
    """
}
