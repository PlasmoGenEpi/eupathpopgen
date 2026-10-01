process CONCAT_SUMMARY_TABLES {
    tag "${out_name}"
    label 'process_single'

    conda "${moduleDir}/environment.yml"
    container "${ workflow.containerEngine in ['singularity', 'apptainer'] && !task.ext.singularity_pull_docker_container ?
        'https://community-cr-prod.seqera.io/docker/registry/v2/blobs/sha256/25/25ec37d72caff047524cad028f190afbd7e97ff61cba29d8172883993c8a5c75/data' :
        'community.wave.seqera.io/library/r_tidyverse:4e1e0dec2f11d009' }"

    input:
    path tables
    val out_name

    output:
    path "${out_name}",  emit: summary
    path "versions.yml", emit: versions

    script:
    def table_list = tables instanceof List ? tables : [tables]
    """
    Rscript ${projectDir}/bin/concat_summary_tables.R \\
        --files "${table_list.join(',')}" \\
        --output ${out_name}

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        r-base: \$(R --version | sed -n '1s/.*version \\([0-9.]*\\).*/\\1/p')
    END_VERSIONS
    """
}
