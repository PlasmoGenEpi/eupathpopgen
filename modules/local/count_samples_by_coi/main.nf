process COUNT_SAMPLES_BY_COI {
    tag "${prefix}:${method}"
    label 'process_single'

    conda "${moduleDir}/environment.yml"
    container "${ workflow.containerEngine in ['singularity', 'apptainer'] && !task.ext.singularity_pull_docker_container
?         'https://community-cr-prod.seqera.io/docker/registry/v2/blobs/sha256/7b/7b7ca5eb26f1bbaf3fba4ea585e789071aa49902df3182030df649f596ac97b1/data'
:         'community.wave.seqera.io/library/pgecore:e9024a6dc6e9a694' }"

    input:
    tuple val(prefix), val(method), path(coi_table)

    output:
    tuple val(prefix), path("${prefix}.${method}.sample_count_per_coi.tsv"), emit: sample_count_per_coi
    path "versions.yml", emit: versions

    script:
    """

    export PATH="\$(Rscript -e 'cat(system.file("exec", package = "PGEcore"))'):\${PATH}"
    count_samples_by_coi \\
        --coi_table ${coi_table} \\
        --output counts.tsv

    awk -v m="${method}" 'BEGIN { FS = OFS = "\\t" } NR == 1 { print "coi_method", \$0; next } { print m, \$0 }' \\
        counts.tsv > ${prefix}.${method}.sample_count_per_coi.tsv

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        r-base: \$(R --version | sed -n '1s/.*version \\([0-9.]*\\).*/\\1/p')
        r-pgecore: \$( Rscript -e 'cat(as.character(packageVersion("PGEcore")))' )
    END_VERSIONS
    """
}
