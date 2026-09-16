/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    IMPORT MODULES / SUBWORKFLOWS / FUNCTIONS
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

include { MULTIQC                } from '../modules/nf-core/multiqc/main'
include { paramsSummaryMap       } from 'plugin/nf-schema'
include { paramsSummaryMultiqc   } from '../subworkflows/nf-core/utils_nfcore_pipeline'
include { softwareVersionsToYAML } from '../subworkflows/nf-core/utils_nfcore_pipeline'
include { methodsDescriptionText } from '../subworkflows/local/utils_nfcore_eupathpopgen_pipeline'

include { ESTIMATE_COI_NAIVE          } from '../modules/local/estimate_coi_naive/main'
include { COUNT_SAMPLES_BY_COI as COUNT_SAMPLES_BY_COI_NAIVE } from '../modules/local/count_samples_by_coi/main'
include { COUNT_SAMPLES_BY_COI as COUNT_SAMPLES_BY_COI_MOIRE } from '../modules/local/count_samples_by_coi/main'
include { RUN_MOIRE                   } from '../modules/local/run_moire/main'
include { DCIFER_IBD                  } from '../modules/local/dcifer_ibd/main'
include { ALLELE_PER_LOCUS_SUMMARY    } from '../modules/local/allele_per_locus_summary/main'
include { PER_LOCUS_POPGEN_SUMMARY    } from '../modules/local/per_locus_popgen_summary/main'
include { INDEX_POPULATION_ASSIGNMENT } from '../modules/local/index_population_assignment/main'
include { SPLIT_ALLELE_TABLE_BY_POP   } from '../modules/local/split_allele_table_by_population/main'

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    RUN MAIN WORKFLOW
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

workflow EUPATHPOPGEN {

    take:
    ch_allele_table
    ch_population_map
    multiqc_config
    multiqc_logo
    multiqc_methods_description
    outdir

    main:

    def ch_versions = channel.empty()
    def ch_multiqc_files = channel.empty()

    //
    // Optional population split → per-population allele tables
    //
    def ch_allele_for_tools = ch_allele_table

    if (params.population_map) {
        INDEX_POPULATION_ASSIGNMENT(ch_population_map)
        ch_versions = ch_versions.mix(INDEX_POPULATION_ASSIGNMENT.out.versions)

        SPLIT_ALLELE_TABLE_BY_POP(
            ch_allele_table,
            INDEX_POPULATION_ASSIGNMENT.out.population_map_indexed
        )
        ch_versions = ch_versions.mix(SPLIT_ALLELE_TABLE_BY_POP.out.versions)

        ch_allele_for_tools = SPLIT_ALLELE_TABLE_BY_POP.out.per_pop_tables.flatten()
    }

    //
    // COI (always naive or moire)
    //
    if (!(params.coi_method in ['naive', 'moire'])) {
        error("Invalid --coi_method '${params.coi_method}'. Allowed values: naive, moire")
    }

    if (params.coi_method == 'naive') {
        ESTIMATE_COI_NAIVE(
            ch_allele_for_tools,
            params.naive_coi_method,
            params.naive_coi_threshold
        )
        ch_versions = ch_versions.mix(ESTIMATE_COI_NAIVE.out.versions)
        COUNT_SAMPLES_BY_COI_NAIVE(ESTIMATE_COI_NAIVE.out.coi_table)
        ch_versions = ch_versions.mix(COUNT_SAMPLES_BY_COI_NAIVE.out.versions)
    }

    //
    // MOIRE runs at most once when needed for COI and/or allele frequencies and/or within-host relatedness.
    // Skipped estimates are still computed internally but not published (see conf/modules.config).
    //
    def run_moire = (params.coi_method == 'moire') ||
        !params.skip_allele_frequencies ||
        !params.skip_within_host_relatedness

    if (run_moire) {
        RUN_MOIRE(ch_allele_for_tools)
        ch_versions = ch_versions.mix(RUN_MOIRE.out.versions)

        if (params.coi_method == 'moire') {
            COUNT_SAMPLES_BY_COI_MOIRE(RUN_MOIRE.out.coi_summary)
            ch_versions = ch_versions.mix(COUNT_SAMPLES_BY_COI_MOIRE.out.versions)
        }
    }

    //
    // Between-host relatedness (Dcifer)
    //
    if (!params.skip_between_host_relatedness) {
        DCIFER_IBD(ch_allele_for_tools)
        ch_versions = ch_versions.mix(DCIFER_IBD.out.versions)
    }

    //
    // Per-locus summaries (always run)
    //
    ALLELE_PER_LOCUS_SUMMARY(ch_allele_for_tools)
    ch_versions = ch_versions.mix(ALLELE_PER_LOCUS_SUMMARY.out.versions)

    PER_LOCUS_POPGEN_SUMMARY(ch_allele_for_tools)
    ch_versions = ch_versions.mix(PER_LOCUS_POPGEN_SUMMARY.out.versions)

    //
    // Collate and save software versions
    //
    def topic_versions = channel.topic("versions")
        .distinct()
        .branch { entry ->
            versions_file: entry instanceof Path
            versions_tuple: true
        }

    def topic_versions_string = topic_versions.versions_tuple
        .map { process, tool, version ->
            [ process[process.lastIndexOf(':')+1..-1], "  ${tool}: ${version}" ]
        }
        .groupTuple(by:0)
        .map { process, tool_versions ->
            tool_versions.unique().sort()
            "${process}:\n${tool_versions.join('\n')}"
        }

    def ch_collated_versions = softwareVersionsToYAML(ch_versions.mix(topic_versions.versions_file))
        .mix(topic_versions_string)
        .collectFile(
            storeDir: "${outdir}/pipeline_info",
            name: 'nf_core_'  +  'eupathpopgen_software_'  + 'mqc_'  + 'versions.yml',
            sort: true,
            newLine: true
        )

    def ch_multiqc_report = channel.empty()
    if (!params.skip_multiqc) {
        ch_multiqc_files = ch_multiqc_files.mix(ch_collated_versions)
        def ch_summary_params = paramsSummaryMap(workflow, parameters_schema: "nextflow_schema.json")
        def ch_workflow_summary = channel.value(paramsSummaryMultiqc(ch_summary_params))
        ch_multiqc_files = ch_multiqc_files.mix(ch_workflow_summary.collectFile(name: 'workflow_summary_mqc.yaml'))
        def ch_multiqc_custom_methods_description = multiqc_methods_description
            ? file(multiqc_methods_description, checkIfExists: true)
            : file("${projectDir}/assets/methods_description_template.yml", checkIfExists: true)
        def ch_methods_description = channel.value(methodsDescriptionText(ch_multiqc_custom_methods_description))
        ch_multiqc_files = ch_multiqc_files.mix(ch_methods_description.collectFile(name: 'methods_description_mqc.yaml', sort: true))
        MULTIQC(
            ch_multiqc_files.flatten().collect().map { files ->
                [
                    [id: 'eupathpopgen'],
                    files,
                    multiqc_config
                        ? file(multiqc_config, checkIfExists: true)
                        : file("${projectDir}/assets/multiqc_config.yml", checkIfExists: true),
                    multiqc_logo ? file(multiqc_logo, checkIfExists: true) : [],
                    [],
                    [],
                ]
            }
        )
        ch_multiqc_report = MULTIQC.out.report.map { _meta, report -> [report] }.toList()
    }

    emit:
    multiqc_report = ch_multiqc_report
    versions       = ch_versions
}
