process PER_LOCUS_POPGEN_SUMMARY {
    tag "${prefix}"
    label 'process_single'

    conda "${moduleDir}/environment.yml"
    container "${ workflow.containerEngine in ['singularity', 'apptainer'] && !task.ext.singularity_pull_docker_container
?         'https://community-cr-prod.seqera.io/docker/registry/v2/blobs/sha256/4e/4eea538b840cfbb0298492f4bcab565f0b8e6869df4b3a2136a76646a547e12b/data'
:         'community.wave.seqera.io/library/per_locus_popgen_summary:d0ac73c2ce57f2a5' }"

    input:
    path allele_table

    output:
    tuple val(prefix), path("${prefix}.per_locus_popgen_summary.tsv"), emit: per_locus_popgen_summary
    path "versions.yml", emit: versions

    script:
    prefix = allele_table.getBaseName(3)
    """
    if ! command -v muscle >/dev/null 2>&1; then
        echo "ERROR: muscle binary not found on PATH (needed by per_locus_popgen_summary)." >&2
        exit 1
    fi

    export PATH="\$(Rscript -e 'cat(system.file("exec", package = "PGEcore"))'):\${PATH}"
    per_locus_popgen_summary \\
        --allele_table ${allele_table} \\
        --output ${prefix}.per_locus_popgen_summary.tsv

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        r-base: \$(R --version | sed -n '1s/.*version \\([0-9.]*\\).*/\\1/p')
        r-pgecore: \$( Rscript -e 'cat(as.character(packageVersion("PGEcore")))' )
        pegas: \$(Rscript -e 'cat(as.character(packageVersion("pegas")))' 2>/dev/null || echo 'NA')
        bioconductor-msa: \$(Rscript -e 'cat(as.character(packageVersion("msa")))' 2>/dev/null || echo 'NA')
        muscle: \$(muscle -version 2>/dev/null | sed -n 's/^muscle \\([0-9.]*[0-9]\\).*/\\1/p')
    END_VERSIONS
    """

    stub:
    prefix = allele_table.getBaseName(3)
    """
    touch ${prefix}.per_locus_popgen_summary.tsv

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        r-base: \$(R --version | sed -n '1s/.*version \\([0-9.]*\\).*/\\1/p')
        r-pgecore: \$( Rscript -e 'cat(as.character(packageVersion("PGEcore")))' )
        pegas: \$(Rscript -e 'cat(as.character(packageVersion("pegas")))' 2>/dev/null || echo 'NA')
        bioconductor-msa: \$(Rscript -e 'cat(as.character(packageVersion("msa")))' 2>/dev/null || echo 'NA')
        muscle: \$(muscle -version 2>/dev/null | sed -n 's/^muscle \\([0-9.]*[0-9]\\).*/\\1/p')
    END_VERSIONS
    """
}
