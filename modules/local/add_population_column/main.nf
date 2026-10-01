process ADD_POPULATION_COLUMN {
    tag "${pop_index}"
    label 'process_single'

    conda "${moduleDir}/environment.yml"
    container "${ workflow.containerEngine in ['singularity', 'apptainer'] && !task.ext.singularity_pull_docker_container
?         'https://community-cr-prod.seqera.io/docker/registry/v2/blobs/sha256/31/3121e85b4799b81b8428434939f60e7c7647b4b0093893ea3277872ceeae4229/data'
:         'community.wave.seqera.io/library/r_tidyverse:a278c76367350736' }"

    input:
    tuple val(pop_index), path(table)
    path population_index_lookup

    output:
    path "${out_name}",  emit: labeled_table
    path "versions.yml", emit: versions

    script:
    out_name = "${table.baseName}.labeled.tsv"
    """
    if [ -s ${population_index_lookup} ]; then
        true_population=\$(awk -F'\\t' -v idx="${pop_index}" '\$1==idx {print \$2; exit}' ${population_index_lookup})
    else
        true_population="${pop_index}"
    fi

    if [ -z "\${true_population}" ]; then
        echo "ERROR: could not resolve population label for index '${pop_index}'" >&2
        exit 1
    fi

    Rscript ${projectDir}/bin/add_population_column.R \\
        --table ${table} \\
        --population "\${true_population}" \\
        --output ${out_name}

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        r-base: \$(R --version | sed -n '1s/.*version \\([0-9.]*\\).*/\\1/p')
    END_VERSIONS
    """

    stub:
    out_name = "${table.baseName}.labeled.tsv"
    """
    touch ${out_name}

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        r-base: \$(R --version | sed -n '1s/.*version \\([0-9.]*\\).*/\\1/p')
    END_VERSIONS
    """
}
