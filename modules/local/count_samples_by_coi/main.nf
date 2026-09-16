process COUNT_SAMPLES_BY_COI {
    tag "${coi_table.simpleName}"
    label 'process_single'
    label 'pgecore'

    conda "${moduleDir}/environment.yml"
    container "${ workflow.containerEngine in ['singularity', 'apptainer'] && !task.ext.singularity_pull_docker_container ?
        'https://community-cr-prod.seqera.io/docker/registry/v2/blobs/sha256/b8/b8b5976e182bb3b8f3b3073fe7ccb663bfa240ef8476d59faf2cccf8b180fe6f/data' :
        'docker.io/rocker/r-ver:4.4.2' }"

    input:
    path coi_table

    output:
    path "sample_count_per_coi.tsv", emit: sample_count_per_coi
    path "versions.yml",             emit: versions

    script:
    """
    Rscript ${projectDir}/bin/ensure_pgecore.R ${params.pgecore_git_repo} ${params.pgecore_git_ref}

    ${projectDir}/bin/pgecore_cli.sh count_samples_by_coi \\
        --coi_table ${coi_table} \\
        --output sample_count_per_coi.tsv

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        r-base: \$(R --version | sed -n '1s/.*version \\([0-9.]*\\).*/\\1/p')
        PGEcore: \$(R_LIBS_USER=$PWD/r_libs Rscript -e 'cat(as.character(packageVersion("PGEcore")))' 2>/dev/null || echo 'NA')
    END_VERSIONS
    """
}
