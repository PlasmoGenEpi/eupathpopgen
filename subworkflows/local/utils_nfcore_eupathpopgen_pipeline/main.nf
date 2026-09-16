//
// Subworkflow with functionality specific to the nf-core/eupathpopgen pipeline
//

include { UTILS_NFSCHEMA_PLUGIN     } from '../../nf-core/utils_nfschema_plugin'
include { paramsSummaryMap          } from 'plugin/nf-schema'
include { paramsHelp                } from 'plugin/nf-schema'
include { completionEmail           } from '../../nf-core/utils_nfcore_pipeline'
include { completionSummary         } from '../../nf-core/utils_nfcore_pipeline'
include { UTILS_NFCORE_PIPELINE     } from '../../nf-core/utils_nfcore_pipeline'
include { UTILS_NEXTFLOW_PIPELINE   } from '../../nf-core/utils_nextflow_pipeline'

include { EXTRACT_ALLELE_TABLE            } from '../../../modules/local/extract_allele_table'
include { EXTRACT_POPULATION_MAP_FROM_PMO } from '../../../modules/local/extract_population_map_from_pmo'

workflow PIPELINE_INITIALISATION {

    take:
    version
    validate_params
    monochrome_logs
    nextflow_cli_args
    outdir
    help
    help_full
    show_hidden

    main:

    ch_versions = channel.empty()

    UTILS_NEXTFLOW_PIPELINE (
        version,
        true,
        outdir,
        workflow.profile.tokenize(',').intersect(['conda', 'mamba']).size() >= 1
    )

    def before_text = """
-\033[2m----------------------------------------------------\033[0m-
                                        \033[0;32m,--.\033[0;30m/\033[0;32m,-.\033[0m
\033[0;34m        ___     __   __   __   ___     \033[0;32m/,-._.--~\'\033[0m
\033[0;34m  |\\ | |__  __ /  ` /  \\ |__) |__         \033[0;33m}  {\033[0m
\033[0;34m  | \\| |       \\__, \\__/ |  \\ |___     \033[0;32m\\`-._,-`-,\033[0m
                                        \033[0;32m`._,._,\'\033[0m
\033[0;35m  nf-core/eupathpopgen ${workflow.manifest.version}\033[0m
-\033[2m----------------------------------------------------\033[0m-
"""
    def after_text = """${workflow.manifest.doi ? "\n* The pipeline\n" : ""}${workflow.manifest.doi.tokenize(",").collect { doi -> "    https://doi.org/${doi.trim().replace('https://doi.org/','')}"}.join("\n")}${workflow.manifest.doi ? "\n" : ""}
* The nf-core framework
    https://doi.org/10.1038/s41587-020-0439-x

* Software dependencies
    https://github.com/nf-core/eupathpopgen/blob/master/CITATIONS.md
"""
    if (monochrome_logs) {
        before_text = before_text.replaceAll(/\033\[[0-9;]*m/, '')
    }

    def command = "nextflow run ${workflow.manifest.name} -profile <docker/singularity/.../institute>,plasmodium --allele_table <ALLELE_TABLE.tsv> --outdir <OUTDIR>"

    UTILS_NFSCHEMA_PLUGIN (
        workflow,
        validate_params,
        null,
        help,
        help_full,
        show_hidden,
        before_text,
        after_text,
        command,
        false
    )

    UTILS_NFCORE_PIPELINE (
        nextflow_cli_args
    )

    validateInputParameters()

    def ch_allele_table = channel.empty()
    def ch_population_map = channel.empty()

    // Normalise comma-separated PMO population fields → space-separated for Python nargs='+'
    def pmo_population_fields_norm = null
    if (params.pmo_population_fields) {
        pmo_population_fields_norm = params.pmo_population_fields
            .tokenize(',')
            .collect { it.trim() }
            .findAll { it }
            .join(' ')
        if (!pmo_population_fields_norm) {
            error("`--pmo_population_fields` was provided but no field names remained after parsing.")
        }
    }

    if (params.pmo) {
        def ch_pmo = channel.fromPath(params.pmo, checkIfExists: true)
        EXTRACT_ALLELE_TABLE(ch_pmo)
        ch_allele_table = EXTRACT_ALLELE_TABLE.out.allele_table
        ch_versions = ch_versions.mix(EXTRACT_ALLELE_TABLE.out.versions)

        if (params.population_map) {
            ch_population_map = channel.fromPath(params.population_map, checkIfExists: true)
        } else if (pmo_population_fields_norm) {
            EXTRACT_POPULATION_MAP_FROM_PMO(
                ch_pmo,
                pmo_population_fields_norm,
                params.pmo_population_separator ?: '_'
            )
            ch_population_map = EXTRACT_POPULATION_MAP_FROM_PMO.out.population_map
            ch_versions = ch_versions.mix(EXTRACT_POPULATION_MAP_FROM_PMO.out.versions)
        }
    } else {
        ch_allele_table = channel.fromPath(params.allele_table, checkIfExists: true)
        if (params.population_map) {
            ch_population_map = channel.fromPath(params.population_map, checkIfExists: true)
        }
    }

    emit:
    allele_table   = ch_allele_table
    population_map = ch_population_map
    versions       = ch_versions
}

workflow PIPELINE_COMPLETION {

    take:
    email
    email_on_fail
    plaintext_email
    outdir
    monochrome_logs
    multiqc_report

    main:
    summary_params = paramsSummaryMap(workflow, parameters_schema: "nextflow_schema.json")
    def multiqc_reports = multiqc_report.toList()

    workflow.onComplete {
        if (email || email_on_fail) {
            completionEmail(
                summary_params,
                email,
                email_on_fail,
                plaintext_email,
                outdir,
                monochrome_logs,
                multiqc_reports.getVal(),
            )
        }

        completionSummary(monochrome_logs)
    }

    workflow.onError {
        log.error "Pipeline failed. Please refer to troubleshooting docs for common issues: https://nf-co.re/docs/running/troubleshooting"
    }
}

def validateInputParameters() {
    if (params.pmo && params.allele_table) {
        error("Provide exactly one of `--pmo` or `--allele_table`, not both.")
    }
    if (!params.pmo && !params.allele_table) {
        error("You must provide either `--pmo` (PMO JSON) or `--allele_table` (PGEcore allele table TSV).")
    }
    if (params.pmo_population_fields && params.population_map) {
        log.warn "`--population_map` takes precedence; `--pmo_population_fields` will be ignored."
    }
    if (params.pmo_population_fields && params.allele_table && !params.pmo) {
        log.warn "`--pmo_population_fields` is only used with `--pmo` and will be ignored for allele-table input."
    }
}

def toolCitationText() {
    def citation_text = [
            "Tools used in the workflow included:",
            "PGEcore (PlasmoGenEpi),",
            params.pmo ? "pmotools (PlasmoGenEpi)," : "",
            (params.coi_method == 'moire' || !params.skip_allele_frequencies || !params.skip_within_host_relatedness) ? "MOIRE (Murphy and Greenhouse)," : "",
            params.skip_between_host_relatedness ? "" : "Dcifer (Gerlovina et al.),",
            "pegas (Paradis),",
            "MultiQC (Ewels et al. 2016)",
            "."
        ].findAll { it }.join(' ').trim()

    return citation_text
}

def toolBibliographyText() {
    def reference_text = [
            "<li>PlasmoGenEpi. PGEcore. https://github.com/PlasmoGenEpi/PGEcore</li>",
            params.pmo ? "<li>PlasmoGenEpi. pmotools-python. https://github.com/PlasmoGenEpi/pmotools-python</li>" : "",
            "<li>Murphy M, Greenhouse B. MOIRE.</li>",
            "<li>Gerlovina I, et al. Dcifer.</li>",
            "<li>Paradis E. pegas: an R package for population genetics. Bioinformatics.</li>",
            "<li>Ewels, P., Magnusson, M., Lundin, S., & Käller, M. (2016). MultiQC: summarize analysis results for multiple tools and samples in a single report. Bioinformatics , 32(19), 3047–3048. doi: /10.1093/bioinformatics/btw354</li>"
        ].findAll { it }.join(' ').trim()

    return reference_text
}

def methodsDescriptionText(mqc_methods_yaml) {
    def meta = [:]
    meta.workflow = workflow.toMap()
    meta["manifest_map"] = workflow.manifest.toMap()

    if (meta.manifest_map.doi) {
        def temp_doi_ref = ""
        def manifest_doi = meta.manifest_map.doi.tokenize(",")
        manifest_doi.each { doi_ref ->
            temp_doi_ref += "(doi: <a href=\'https://doi.org/${doi_ref.replace("https://doi.org/", "").replace(" ", "")}\'>${doi_ref.replace("https://doi.org/", "").replace(" ", "")}</a>), "
        }
        meta["doi_text"] = temp_doi_ref.substring(0, temp_doi_ref.length() - 2)
    } else meta["doi_text"] = ""
    meta["nodoi_text"] = meta.manifest_map.doi ? "" : "<li>If available, make sure to update the text to include the Zenodo DOI of version of the pipeline used. </li>"

    meta["tool_citations"] = toolCitationText().replaceAll(", \\.", ".").replaceAll("\\. \\.", ".").replaceAll(", \\.", ".")
    meta["tool_bibliography"] = toolBibliographyText()

    def methods_text = mqc_methods_yaml.text
    def engine =  new groovy.text.SimpleTemplateEngine()
    def description_html = engine.createTemplate(methods_text).make(meta)

    return description_html.toString()
}
