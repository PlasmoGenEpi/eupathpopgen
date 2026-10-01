process ALLELE_PER_LOCUS_SUMMARY {
    tag "${prefix}"
    label 'process_single'
    label 'pgecore'

    conda "${moduleDir}/environment.yml"
    container "${ workflow.containerEngine in ['singularity', 'apptainer'] && !task.ext.singularity_pull_docker_container ?
        'https://community-cr-prod.seqera.io/docker/registry/v2/blobs/sha256/a3/a3f6b6ae8a3fa56533afbf35e8b01adde48df5640095715373bbfda0380593bc/data' :
        'community.wave.seqera.io/library/r-base_r-pgecore:3c5180998a8cccc0' }"

    input:
    path allele_table

    output:
    tuple val(prefix), path("${prefix}.allele_summary_by_target.tsv"), emit: allele_summary_by_target
    path "versions.yml", emit: versions

    script:
    prefix = allele_table.getBaseName(3)
    """

    ${projectDir}/bin/pgecore_cli.sh allele_per_locus_summary \\
        --allele_table ${allele_table} \\
        --output ${prefix}.allele_summary_by_target.tsv

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        r-base: \$(R --version | sed -n '1s/.*version \\([0-9.]*\\).*/\\1/p')
        PGEcore: \$(Rscript -e 'cat(as.character(packageVersion("PGEcore")))' 2>/dev/null || echo 'NA')
    END_VERSIONS
    """
}
