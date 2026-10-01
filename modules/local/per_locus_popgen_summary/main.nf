process PER_LOCUS_POPGEN_SUMMARY {
    tag "${prefix}"
    label 'process_single'

    conda "${moduleDir}/environment.yml"
    container "${ workflow.containerEngine in ['singularity', 'apptainer'] && !task.ext.singularity_pull_docker_container
?         'https://community-cr-prod.seqera.io/docker/registry/v2/blobs/sha256/5c/5cf58632508eb0af0e240343c102a1aefa374dcd46458fbfc8a102f2e6328921/data'
:         'community.wave.seqera.io/library/per_locus_popgen_summary:7f6f43c8231ce06f' }"

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
}
