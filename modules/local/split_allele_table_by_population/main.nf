process SPLIT_ALLELE_TABLE_BY_POP {
    tag "${allele_table.simpleName}"
    label 'process_single'

    conda "${moduleDir}/environment.yml"
    container "${ workflow.containerEngine in ['singularity', 'apptainer'] && !task.ext.singularity_pull_docker_container
?         'https://community-cr-prod.seqera.io/docker/registry/v2/blobs/sha256/31/3121e85b4799b81b8428434939f60e7c7647b4b0093893ea3277872ceeae4229/data'
:         'community.wave.seqera.io/library/r_tidyverse:a278c76367350736' }"

    input:
    path allele_table
    path population_map

    output:
    path "*.allele_table.tsv.gz", emit: per_pop_tables
    path "unassigned_specimens.txt", optional: true, emit: unassigned_report
    path "versions.yml", emit: versions

    script:
    """
    Rscript ${projectDir}/bin/split_table_by_population_map.R \\
        --input_table_fnp ${allele_table} \\
        --population_map ${population_map} \\
        --split_col population_index \\
        --identifier_col specimen_name \\
        --output_stub .allele_table.tsv.gz

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        r-base: \$(R --version | sed -n '1s/.*version \\([0-9.]*\\).*/\\1/p')
    END_VERSIONS
    """

    stub:
    """
    echo "" | gzip > popidx_001.allele_table.tsv.gz

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        r-base: \$(R --version | sed -n '1s/.*version \\([0-9.]*\\).*/\\1/p')
    END_VERSIONS
    """
}
