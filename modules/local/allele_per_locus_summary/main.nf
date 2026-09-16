process ALLELE_PER_LOCUS_SUMMARY {
    tag "${allele_table.simpleName}"
    label 'process_single'
    label 'pgecore'

    conda "${moduleDir}/environment.yml"
    container "${ workflow.containerEngine in ['singularity', 'apptainer'] && !task.ext.singularity_pull_docker_container ?
        'https://community-cr-prod.seqera.io/docker/registry/v2/blobs/sha256/b8/b8b5976e182bb3b8f3b3073fe7ccb663bfa240ef8476d59faf2cccf8b180fe6f/data' :
        'docker.io/rocker/r-ver:4.4.2' }"

    input:
    path allele_table

    output:
    path "allele_summary_by_target.tsv", emit: allele_summary_by_target
    path "versions.yml",                 emit: versions

    script:
    """
    Rscript ${projectDir}/bin/ensure_pgecore.R ${params.pgecore_git_repo} ${params.pgecore_git_ref}

    ${projectDir}/bin/pgecore_cli.sh allele_per_locus_summary \\
        --allele_table ${allele_table} \\
        --output allele_summary_by_target.tsv

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        r-base: \$(R --version | sed -n '1s/.*version \\([0-9.]*\\).*/\\1/p')
        PGEcore: \$(R_LIBS_USER=$PWD/r_libs Rscript -e 'cat(as.character(packageVersion("PGEcore")))' 2>/dev/null || echo 'NA')
    END_VERSIONS
    """
}
