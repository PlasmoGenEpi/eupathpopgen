process INDEX_POPULATION_ASSIGNMENT {
    tag "${population_map.simpleName}"
    label 'process_single'

    conda "${moduleDir}/environment.yml"
    container "${ workflow.containerEngine in ['singularity', 'apptainer'] && !task.ext.singularity_pull_docker_container
?         'https://community-cr-prod.seqera.io/docker/registry/v2/blobs/sha256/31/3121e85b4799b81b8428434939f60e7c7647b4b0093893ea3277872ceeae4229/data'
:         'community.wave.seqera.io/library/r_tidyverse:a278c76367350736' }"

    input:
    path population_map

    output:
    path "population_map_indexed.tsv", emit: population_map_indexed
    path "population_index_lookup.tsv", emit: population_index_lookup
    path "versions.yml", emit: versions

    script:
    """
    Rscript ${projectDir}/bin/index_population_assignment.R \\
        --population_map ${population_map} \\
        --population_col population \\
        --identifier_col specimen_name \\
        --indexed_output population_map_indexed.tsv \\
        --lookup_output population_index_lookup.tsv

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        r-base: \$(R --version | sed -n '1s/.*version \\([0-9.]*\\).*/\\1/p')
    END_VERSIONS
    """
}
