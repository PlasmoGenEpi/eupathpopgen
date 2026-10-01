process ALLELE_PER_LOCUS_SUMMARY {
    tag "${prefix}"
    label 'process_single'

    conda "${moduleDir}/environment.yml"
    container "${ workflow.containerEngine in ['singularity', 'apptainer'] && !task.ext.singularity_pull_docker_container
?         'https://community-cr-prod.seqera.io/docker/registry/v2/blobs/sha256/7b/7b7ca5eb26f1bbaf3fba4ea585e789071aa49902df3182030df649f596ac97b1/data'
:         'community.wave.seqera.io/library/pgecore:e9024a6dc6e9a694' }"

    input:
    path allele_table

    output:
    tuple val(prefix), path("${prefix}.allele_summary_by_target.tsv"), emit: allele_summary_by_target
    path "versions.yml", emit: versions

    script:
    prefix = allele_table.getBaseName(3)
    """

    export PATH="\$(Rscript -e 'cat(system.file("exec", package = "PGEcore"))'):\${PATH}"
    allele_per_locus_summary \\
        --allele_table ${allele_table} \\
        --output ${prefix}.allele_summary_by_target.tsv

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        r-base: \$(R --version | sed -n '1s/.*version \\([0-9.]*\\).*/\\1/p')
        r-pgecore: \$( Rscript -e 'cat(as.character(packageVersion("PGEcore")))' )
    END_VERSIONS
    """

    stub:
    prefix = allele_table.getBaseName(3)
    """
    touch ${prefix}.allele_summary_by_target.tsv

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        r-base: \$(R --version | sed -n '1s/.*version \\([0-9.]*\\).*/\\1/p')
        r-pgecore: \$( Rscript -e 'cat(as.character(packageVersion("PGEcore")))' )
    END_VERSIONS
    """
}
