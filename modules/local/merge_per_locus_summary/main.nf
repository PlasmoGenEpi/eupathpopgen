process MERGE_PER_LOCUS_SUMMARY {
    tag "${prefix}"
    label 'process_single'

    conda "${moduleDir}/environment.yml"
    container "${ workflow.containerEngine in ['singularity', 'apptainer'] && !task.ext.singularity_pull_docker_container
?         'https://community-cr-prod.seqera.io/docker/registry/v2/blobs/sha256/50/50c7890c34e1947af8358cb959dec80816bdb20368162fdbc2643c116105445b/data'
:         'community.wave.seqera.io/library/merge_per_locus_summary:cd27cc7980d17f7e' }"

    input:
    tuple val(prefix), path(allele_summary), path(popgen_summary), path(he_summary)

    output:
    tuple val(prefix), path("${prefix}.per_locus_summary.tsv"), emit: per_locus_summary
    path "versions.yml", emit: versions

    script:
    def he_file = (he_summary instanceof Path) ? he_summary :
        ((he_summary instanceof List && !he_summary.isEmpty()) ? he_summary[0] : null)
    def he_path = he_file ? he_file.toString() : ''
    """
    Rscript -e '
      allele <- utils::read.delim("${allele_summary}", check.names = FALSE, stringsAsFactors = FALSE)
      popgen <- utils::read.delim("${popgen_summary}", check.names = FALSE, stringsAsFactors = FALSE)
      if (!("target_name" %in% names(allele))) stop("allele summary missing target_name")
      if (!("target_name" %in% names(popgen))) stop("popgen summary missing target_name")
      merged <- merge(allele, popgen, by = "target_name", all = TRUE, sort = TRUE)

      he_path <- "${he_path}"
      if (nzchar(he_path) && file.exists(he_path)) {
        he <- utils::read.delim(he_path, check.names = FALSE, stringsAsFactors = FALSE)
        if (!("target_name" %in% names(he))) stop("he summary missing target_name")
        keep <- intersect(c("target_name", "he"), names(he))
        he <- he[, keep, drop = FALSE]
        merged <- merge(merged, he, by = "target_name", all = TRUE, sort = TRUE)
      }

      utils::write.table(
        merged,
        file = "${prefix}.per_locus_summary.tsv",
        sep = "\\t",
        row.names = FALSE,
        quote = FALSE
      )
    '

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        r-base: \$(R --version | sed -n '1s/.*version \\([0-9.]*\\).*/\\1/p')
    END_VERSIONS
    """
}
