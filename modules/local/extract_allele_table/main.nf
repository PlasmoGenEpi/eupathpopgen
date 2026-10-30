/*
 * STEP - EXTRACT_ALLELE_TABLE
 * Extract allele table from PMO file given a bioinformatics ID
 */

process EXTRACT_ALLELE_TABLE {

    label 'process_single'

    conda "${moduleDir}/environment.yml"
    container "${ workflow.containerEngine in ['singularity', 'apptainer'] && !task.ext.singularity_pull_docker_container
?         'https://community-cr-prod.seqera.io/docker/registry/v2/blobs/sha256/48/486b002855a25cd4739d4f3da8f069b03c157e7a91c95b02bba56cf20438d202/data'
:         'community.wave.seqera.io/library/pmotools:b396e7b3d4cedca6' }"

    input:
    path pmo

    output:
    path "allele_table.tsv", emit: allele_table
    path "versions.yml", emit: versions

    script:
    """
    pmotools-python extract_allele_table \
        --file ${pmo} \
        --microhap_fields "reads" \
        --default_base_col_names specimen_name,target_name,seq \
        --output allele_table

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        pmotools-python: \$( pmotools-python --version 2>/dev/null || echo 'N/A' )
    END_VERSIONS
    """

    stub:
    """
    touch allele_table.tsv

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        pmotools-python: \$( pmotools-python --version 2>/dev/null || echo 'N/A' )
    END_VERSIONS
    """
}
