process STANDARDIZE_COI_TABLE {
    tag "${prefix}:${method}"
    label 'process_single'

    conda "${moduleDir}/environment.yml"
    container "${ workflow.containerEngine in ['singularity', 'apptainer'] && !task.ext.singularity_pull_docker_container
?         'https://community-cr-prod.seqera.io/docker/registry/v2/blobs/sha256/31/3121e85b4799b81b8428434939f60e7c7647b4b0093893ea3277872ceeae4229/data'
:         'community.wave.seqera.io/library/r_tidyverse:a278c76367350736' }"

    input:
    tuple val(prefix), path(coi_table)
    val method

    output:
    tuple val(prefix), val(method), path("${prefix}.${method}.coi_table.tsv"), emit: coi_table
    path "versions.yml",                                                        emit: versions

    script:
    """
    Rscript ${projectDir}/bin/standardize_coi_table.R \\
        --table ${coi_table} \\
        --method ${method} \\
        --output ${prefix}.${method}.coi_table.tsv

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        r-base: \$(R --version | sed -n '1s/.*version \\([0-9.]*\\).*/\\1/p')
    END_VERSIONS
    """

    stub:
    """
    touch ${prefix}.${method}.coi_table.tsv

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        r-base: \$(R --version | sed -n '1s/.*version \\([0-9.]*\\).*/\\1/p')
    END_VERSIONS
    """
}
