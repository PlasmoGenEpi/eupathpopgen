#!/usr/bin/env nextflow
/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    nf-core/eupathpopgen
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    Github : https://github.com/nf-core/eupathpopgen
    Website: https://nf-co.re/eupathpopgen
    Slack  : https://nfcore.slack.com/channels/eupathpopgen
----------------------------------------------------------------------------------------
*/

include { EUPATHPOPGEN  } from './workflows/eupathpopgen'
include { PIPELINE_INITIALISATION } from './subworkflows/local/utils_nfcore_eupathpopgen_pipeline'
include { PIPELINE_COMPLETION     } from './subworkflows/local/utils_nfcore_eupathpopgen_pipeline'

workflow NFCORE_EUPATHPOPGEN {

    take:
    ch_allele_table
    ch_population_map

    main:
    EUPATHPOPGEN (
        ch_allele_table,
        ch_population_map,
        params.multiqc_config,
        params.multiqc_logo,
        params.multiqc_methods_description,
        params.outdir,
    )
    emit:
    multiqc_report = EUPATHPOPGEN.out.multiqc_report
}

workflow {

    main:
    PIPELINE_INITIALISATION (
        params.version,
        params.validate_params,
        params.monochrome_logs,
        args,
        params.outdir,
        params.allele_table,
        params.population_map,
        params.help,
        params.help_full,
        params.show_hidden
    )

    NFCORE_EUPATHPOPGEN (
        PIPELINE_INITIALISATION.out.allele_table,
        PIPELINE_INITIALISATION.out.population_map
    )

    PIPELINE_COMPLETION (
        params.email,
        params.email_on_fail,
        params.plaintext_email,
        params.outdir,
        params.monochrome_logs,
        NFCORE_EUPATHPOPGEN.out.multiqc_report
    )
}
