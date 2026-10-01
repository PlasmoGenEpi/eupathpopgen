process STANDARDIZE_COI_TABLE {
    tag "${prefix}:${method}"
    label 'process_single'

    conda "${moduleDir}/environment.yml"
    container "${ workflow.containerEngine in ['singularity', 'apptainer'] && !task.ext.singularity_pull_docker_container ?
        'https://community-cr-prod.seqera.io/docker/registry/v2/blobs/sha256/25/25ec37d72caff047524cad028f190afbd7e97ff61cba29d8172883993c8a5c75/data' :
        'community.wave.seqera.io/library/r_tidyverse:4e1e0dec2f11d009' }"

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
}
