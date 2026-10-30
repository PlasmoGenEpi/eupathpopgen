process ESTIMATE_COI_NAIVE {
    tag "${prefix}"
    label 'process_single'

    conda "${moduleDir}/environment.yml"
    container "${ workflow.containerEngine in ['singularity', 'apptainer'] && !task.ext.singularity_pull_docker_container
?         'https://community-cr-prod.seqera.io/docker/registry/v2/blobs/sha256/8b/8bb7bd8a2b78f4d460b00f1df86ec9e05e68ae1cfb2132665575995df5404ce1/data'
:         'community.wave.seqera.io/library/pgecore:7027edf49864476b' }"

    input:
    path allele_table
    val method
    val threshold

    output:
    tuple val(prefix), path("${prefix}.coi_table.tsv"), emit: coi_table
    path "versions.yml", emit: versions

    script:
    prefix = allele_table.getBaseName(3)
    def threshold_arg = method == "integer_method" ? "--integer_threshold ${threshold}" : "--quantile_threshold ${threshold}"
    if (!(method in ["integer_method", "quantile_method"])) {
        error("'method' must be integer_method or quantile_method. Provided: ${method}")
    }
    """

    export PATH="\$(Rscript -e 'cat(system.file("exec", package = "PGEcore"))'):\${PATH}"
    estimate_coi_naive \\
        --allele_table ${allele_table} \\
        --output ${prefix}.coi_table.tsv \\
        --method ${method} \\
        ${threshold_arg}

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        r-base: \$(R --version | sed -n '1s/.*version \\([0-9.]*\\).*/\\1/p')
        r-pgecore: \$( Rscript -e 'cat(as.character(packageVersion("PGEcore")))' )
    END_VERSIONS
    """

    stub:
    prefix = allele_table.getBaseName(3)
    """
    touch ${prefix}.coi_table.tsv

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        r-base: \$(R --version | sed -n '1s/.*version \\([0-9.]*\\).*/\\1/p')
        r-pgecore: \$( Rscript -e 'cat(as.character(packageVersion("PGEcore")))' )
    END_VERSIONS
    """
}
