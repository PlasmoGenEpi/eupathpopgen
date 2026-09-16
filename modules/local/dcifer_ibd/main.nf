process DCIFER_IBD {
    tag "${allele_table.simpleName}"
    label 'process_low'
    label 'pgecore'

    conda "${moduleDir}/environment.yml"
    container "${ workflow.containerEngine in ['singularity', 'apptainer'] && !task.ext.singularity_pull_docker_container ?
        'https://community-cr-prod.seqera.io/docker/registry/v2/blobs/sha256/05/05f1d70c93e8c8b63e03d0b0e1e29d4fedf8994a66f43a8886539bcbadafe10e/data' :
        'docker.io/rocker/r-ver:4.4.2' }"

    input:
    path allele_table

    output:
    path "btwn_host_rel.tsv", emit: btwn_host_rel
    path "versions.yml",      emit: versions

    script:
    def rnull = params.dcifer_rnull != null ? "--rnull ${params.dcifer_rnull}" : ''
    def alpha = params.dcifer_alpha != null ? "--alpha ${params.dcifer_alpha}" : ''
    def estm  = params.dcifer_use_estm ? '--use_estm' : ''
    """
    Rscript ${projectDir}/bin/ensure_pgecore.R ${params.pgecore_git_repo} ${params.pgecore_git_ref}

    ${projectDir}/bin/pgecore_cli.sh dcifer_ibd_wrapper \\
        --allele_table ${allele_table} \\
        --relatedness_output btwn_host_rel.tsv \\
        --threads ${task.cpus} \\
        ${rnull} ${alpha} ${estm}

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        r-base: \$(R --version | sed -n '1s/.*version \\([0-9.]*\\).*/\\1/p')
        PGEcore: \$(R_LIBS_USER=$PWD/r_libs Rscript -e 'cat(as.character(packageVersion("PGEcore")))' 2>/dev/null || echo 'NA')
        dcifer: \$(R_LIBS_USER=$PWD/r_libs Rscript -e 'cat(as.character(packageVersion("dcifer")))' 2>/dev/null || echo 'NA')
    END_VERSIONS
    """
}
