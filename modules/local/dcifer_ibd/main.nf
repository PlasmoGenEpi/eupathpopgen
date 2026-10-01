process DCIFER_IBD {
    tag "${prefix}"
    label 'process_low'
    label 'pgecore'

    conda "${moduleDir}/environment.yml"
    container "${ workflow.containerEngine in ['singularity', 'apptainer'] && !task.ext.singularity_pull_docker_container ?
        'https://community-cr-prod.seqera.io/docker/registry/v2/blobs/sha256/f0/f00498cda4cb37373162973d6166243860edf51e4be8c22590039466a3712092/data' :
        'community.wave.seqera.io/library/r-base_r-pgecore_r-dcifer_r-doparallel_pruned:1d09303086a65554' }"

    input:
    path allele_table

    output:
    tuple val(prefix), path("${prefix}.btwn_host_rel.tsv"), emit: btwn_host_rel
    path "versions.yml", emit: versions

    script:
    prefix = allele_table.getBaseName(3)
    def rnull = params.dcifer_rnull != null ? "--rnull ${params.dcifer_rnull}" : ''
    def alpha = params.dcifer_alpha != null ? "--alpha ${params.dcifer_alpha}" : ''
    def estm  = params.dcifer_use_estm ? '--use_estm' : ''
    """

    ${projectDir}/bin/pgecore_cli.sh dcifer_ibd_wrapper \\
        --allele_table ${allele_table} \\
        --relatedness_output ${prefix}.btwn_host_rel.tsv \\
        --threads ${task.cpus} \\
        ${rnull} ${alpha} ${estm}

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        r-base: \$(R --version | sed -n '1s/.*version \\([0-9.]*\\).*/\\1/p')
        PGEcore: \$(Rscript -e 'cat(as.character(packageVersion("PGEcore")))' 2>/dev/null || echo 'NA')
        dcifer: \$(Rscript -e 'cat(as.character(packageVersion("dcifer")))' 2>/dev/null || echo 'NA')
    END_VERSIONS
    """
}
