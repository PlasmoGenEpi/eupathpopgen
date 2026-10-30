process RUN_MOIRE {
    tag "${prefix}"
    label 'process_low'

    conda "${moduleDir}/environment.yml"
    container "${ workflow.containerEngine in ['singularity', 'apptainer'] && !task.ext.singularity_pull_docker_container
?         'https://community-cr-prod.seqera.io/docker/registry/v2/blobs/sha256/42/426b6b3d29b0ef162b65d262f2c3fe3356b94e4e8c2dc367efe0372744a9082e/data'
:         'community.wave.seqera.io/library/run_moire:fc0f850602a4446b' }"

    input:
    path allele_table

    output:
    tuple val(prefix), path("${prefix}.coi_summary.tsv"),           emit: coi_summary
    tuple val(prefix), path("${prefix}.he_summary.tsv"),            emit: he_summary
    tuple val(prefix), path("${prefix}.allele_freq_summary.tsv"),   emit: allele_freq_summary
    tuple val(prefix), path("${prefix}.relatedness_summary.tsv"),   emit: relatedness_summary
    tuple val(prefix), path("${prefix}.effective_coi_summary.tsv"), emit: effective_coi_summary
    tuple val(prefix), path("${prefix}.convergence_summary.tsv"),   emit: convergence_summary
    path "mcmc_results.rds",                                        emit: mcmc_results, optional: true
    path "versions.yml",                                            emit: versions

    script:
    prefix = allele_table.getBaseName(3)
    def extra_args = task.ext.args ?: ''
    """
    export PATH="\$(Rscript -e 'cat(system.file("exec", package = "PGEcore"))'):\${PATH}"
    moire_wrapper \\
        --allele_table ${allele_table} \\
        --coi_output ${prefix}.coi_summary.tsv \\
        --he_output ${prefix}.he_summary.tsv \\
        --allele_freq_output ${prefix}.allele_freq_summary.tsv \\
        --relatedness_output ${prefix}.relatedness_summary.tsv \\
        --effective_coi_output ${prefix}.effective_coi_summary.tsv \\
        --convergence_summary_output ${prefix}.convergence_summary.tsv \\
        --threads ${task.cpus} \\
        ${extra_args}

    # Canonical column order: target_name, seq, freq, then remaining columns
    Rscript -e '
      af <- utils::read.delim("${prefix}.allele_freq_summary.tsv", check.names = FALSE, stringsAsFactors = FALSE)
      first <- c("target_name", "seq", "freq")
      missing <- setdiff(first, names(af))
      if (length(missing)) stop("allele_freq_summary missing columns: ", paste(missing, collapse = ", "))
      af <- af[, c(first, setdiff(names(af), first)), drop = FALSE]
      utils::write.table(af, "${prefix}.allele_freq_summary.tsv", sep = "\t", row.names = FALSE, quote = FALSE)
    '

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        r-base: \$(R --version | sed -n '1s/.*version \\([0-9.]*\\).*/\\1/p')
        r-pgecore: \$( Rscript -e 'cat(as.character(packageVersion("PGEcore")))' )
        r-moire: \$( Rscript -e 'cat(as.character(packageVersion("moire")))' )
    END_VERSIONS
    """

    stub:
    prefix = allele_table.getBaseName(3)
    """
    touch ${prefix}.coi_summary.tsv
    touch ${prefix}.he_summary.tsv
    touch ${prefix}.allele_freq_summary.tsv
    touch ${prefix}.relatedness_summary.tsv
    touch ${prefix}.effective_coi_summary.tsv
    touch ${prefix}.convergence_summary.tsv

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        r-base: \$(R --version | sed -n '1s/.*version \\([0-9.]*\\).*/\\1/p')
        r-pgecore: \$( Rscript -e 'cat(as.character(packageVersion("PGEcore")))' )
        r-moire: \$( Rscript -e 'cat(as.character(packageVersion("moire")))' )
    END_VERSIONS
    """
}
