process ESTIMATE_COI_NAIVE {
    tag "${prefix}"
    label 'process_single'

    conda "${moduleDir}/environment.yml"
    container "${ workflow.containerEngine in ['singularity', 'apptainer'] && !task.ext.singularity_pull_docker_container ?
        'https://community-cr-prod.seqera.io/docker/registry/v2/blobs/sha256/a3/a3f6b6ae8a3fa56533afbf35e8b01adde48df5640095715373bbfda0380593bc/data' :
        'community.wave.seqera.io/library/r-base_r-pgecore:3c5180998a8cccc0' }"

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
}
