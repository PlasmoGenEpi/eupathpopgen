process DCIFER_IBD {
    tag "${prefix}"
    label 'process_low'

    conda "${moduleDir}/environment.yml"
    container "${ workflow.containerEngine in ['singularity', 'apptainer'] && !task.ext.singularity_pull_docker_container
?         'https://community-cr-prod.seqera.io/docker/registry/v2/blobs/sha256/b1/b136d93933a1fd1a035e54963270afeb7f4b6b3fd7b1d755dc994466987c62e7/data'
:         'community.wave.seqera.io/library/dcifer_ibd:04eaabd9a8a3f281' }"

    input:
    path allele_table

    output:
    tuple val(prefix), path("${prefix}.btwn_host_rel.tsv"), emit: btwn_host_rel
    path "versions.yml", emit: versions

    script:
    prefix = allele_table.getBaseName(3)
    def extra_args = task.ext.args ?: ''
    """

    export PATH="\$(Rscript -e 'cat(system.file("exec", package = "PGEcore"))'):\${PATH}"
    dcifer_ibd_wrapper \\
        --allele_table ${allele_table} \\
        --relatedness_output ${prefix}.btwn_host_rel.tsv \\
        --threads ${task.cpus} \\
        ${extra_args}

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        r-base: \$(R --version | sed -n '1s/.*version \\([0-9.]*\\).*/\\1/p')
        r-pgecore: \$( Rscript -e 'cat(as.character(packageVersion("PGEcore")))' )
        dcifer: \$(Rscript -e 'cat(as.character(packageVersion("dcifer")))' 2>/dev/null || echo 'NA')
    END_VERSIONS
    """
}
