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
include { STANDARDIZE_COI_TABLE as STANDARDIZE_COI_NAIVE } from '../modules/local/standardize_coi_table/main'
include { STANDARDIZE_COI_TABLE as STANDARDIZE_COI_MOIRE } from '../modules/local/standardize_coi_table/main'
include { COUNT_SAMPLES_BY_COI        } from '../modules/local/count_samples_by_coi/main'
include { RUN_MOIRE                   } from '../modules/local/run_moire/main'
include { DCIFER_IBD                  } from '../modules/local/dcifer_ibd/main'
include { ALLELE_PER_LOCUS_SUMMARY    } from '../modules/local/allele_per_locus_summary/main'
include { PER_LOCUS_POPGEN_SUMMARY    } from '../modules/local/per_locus_popgen_summary/main'
include { MERGE_PER_LOCUS_SUMMARY     } from '../modules/local/merge_per_locus_summary/main'
include { SPLIT_ALLELE_TABLE_BY_POP   } from '../modules/local/split_allele_table_by_population/main'
include { ADD_POPULATION_COLUMN as ADD_POP_COI_TABLE } from '../modules/local/add_population_column/main'
include { ADD_POPULATION_COLUMN as ADD_POP_SAMPLE_COUNT } from '../modules/local/add_population_column/main'
include { ADD_POPULATION_COLUMN as ADD_POP_COI_SUMMARY } from '../modules/local/add_population_column/main'
include { ADD_POPULATION_COLUMN as ADD_POP_EFFECTIVE_COI } from '../modules/local/add_population_column/main'
include { ADD_POPULATION_COLUMN as ADD_POP_CONVERGENCE } from '../modules/local/add_population_column/main'
include { ADD_POPULATION_COLUMN as ADD_POP_ALLELE_FREQ } from '../modules/local/add_population_column/main'
include { ADD_POPULATION_COLUMN as ADD_POP_HE } from '../modules/local/add_population_column/main'
include { ADD_POPULATION_COLUMN as ADD_POP_WITHIN_HOST } from '../modules/local/add_population_column/main'
include { ADD_POPULATION_COLUMN as ADD_POP_BETWEEN_HOST } from '../modules/local/add_population_column/main'
include { ADD_POPULATION_COLUMN as ADD_POP_PER_TARGET } from '../modules/local/add_population_column/main'
include { CONCAT_SUMMARY_TABLES as CONCAT_COI_SUMMARY } from '../modules/local/concat_summary_tables/main'
include { CONCAT_SUMMARY_TABLES as CONCAT_SAMPLE_COUNT } from '../modules/local/concat_summary_tables/main'
include { CONCAT_SUMMARY_TABLES as CONCAT_MOIRE_COI } from '../modules/local/concat_summary_tables/main'
include { CONCAT_SUMMARY_TABLES as CONCAT_EFFECTIVE_COI } from '../modules/local/concat_summary_tables/main'
include { CONCAT_SUMMARY_TABLES as CONCAT_CONVERGENCE } from '../modules/local/concat_summary_tables/main'
include { CONCAT_SUMMARY_TABLES as CONCAT_ALLELE_FREQ } from '../modules/local/concat_summary_tables/main'
include { CONCAT_SUMMARY_TABLES as CONCAT_HE } from '../modules/local/concat_summary_tables/main'
include { CONCAT_SUMMARY_TABLES as CONCAT_WITHIN_HOST } from '../modules/local/concat_summary_tables/main'
include { CONCAT_SUMMARY_TABLES as CONCAT_BETWEEN_HOST } from '../modules/local/concat_summary_tables/main'
include { CONCAT_SUMMARY_TABLES as CONCAT_PER_TARGET } from '../modules/local/concat_summary_tables/main'

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    RUN MAIN WORKFLOW
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

workflow EUPATHPOPGEN {

    take:
    ch_allele_table
    ch_population_assignment
    ch_population_index_lookup
    ch_versions
    multiqc_config
    multiqc_logo
    multiqc_methods_description
    outdir

    main:

    def ch_multiqc_files = channel.empty()

    //
    // Optional population split → per-population allele tables keyed by popidx_NNN
    //
    def ch_allele_for_tools = ch_allele_table
    def has_population_assignment = params.population_assignment || (params.pmo && params.pmo_population_fields)

    def ch_lookup = has_population_assignment
        ? ch_population_index_lookup.collect()
        : channel.value([file("${projectDir}/assets/empty_population_index_lookup.tsv")])

    def ch_unassigned_count = channel.empty()
    if (has_population_assignment) {
        SPLIT_ALLELE_TABLE_BY_POP(
            ch_allele_table,
            ch_population_assignment
        )
        ch_versions = ch_versions.mix(SPLIT_ALLELE_TABLE_BY_POP.out.versions)
        ch_allele_for_tools = SPLIT_ALLELE_TABLE_BY_POP.out.per_pop_tables.flatten()

        // Specimens missing from the population assignment are excluded from every population-level output
        ch_unassigned_count = SPLIT_ALLELE_TABLE_BY_POP.out.unassigned_report
            .map { report -> report.readLines().findAll { line -> line.trim() }.size() }
        ch_unassigned_count.subscribe { n_unassigned ->
            log.warn "${n_unassigned} specimen(s) not found in the population assignment were excluded from all outputs. " +
                "See ${params.outdir}/unassigned_specimens.txt"
        }
    }

    // Remap popidx → population_label for single-population runs (drugres parity)
    def remap_pop = { pop_index, table ->
        has_population_assignment ? [pop_index, table] : [params.population_label, table]
    }

    //
    // COI: one or more methods (comma-separated --coi_method), unless --skip_coi.
    // One method: coi_summary with a coi column (no coi_method). Several: wide (coi_<method>).
    //
    def allowed_coi_methods = ['naive', 'moire']
    def coi_methods = []
    if (!params.skip_coi) {
        coi_methods = params.coi_method.toString().tokenize(',')*.trim().findAll { it }.unique()
        def invalid_coi_methods = coi_methods - allowed_coi_methods
        if (!coi_methods || invalid_coi_methods) {
            error("Invalid --coi_method '${params.coi_method}'. Use one or more of ${allowed_coi_methods.join(', ')}, comma-separated (e.g. 'naive,moire').")
        }
    }

    // [popidx, coi_method, table(coi_method, specimen_name, coi)]
    def ch_coi_by_method = channel.empty()

    if ('naive' in coi_methods) {
        ESTIMATE_COI_NAIVE(
            ch_allele_for_tools,
            params.naive_coi_method,
            params.naive_coi_threshold
        )
        ch_versions = ch_versions.mix(ESTIMATE_COI_NAIVE.out.versions)

        STANDARDIZE_COI_NAIVE(ESTIMATE_COI_NAIVE.out.coi_table, 'naive')
        ch_versions = ch_versions.mix(STANDARDIZE_COI_NAIVE.out.versions)
        ch_coi_by_method = ch_coi_by_method.mix(STANDARDIZE_COI_NAIVE.out.coi_table)
    }

    //
    // MOIRE runs at most once when needed for COI and/or allele frequencies and/or within-host relatedness.
    //
    def run_moire = ('moire' in coi_methods) ||
        !params.skip_allele_frequencies ||
        !params.skip_within_host_relatedness

    def ch_he_by_table = channel.empty()
    if (run_moire) {
        RUN_MOIRE(ch_allele_for_tools)
        ch_versions = ch_versions.mix(RUN_MOIRE.out.versions)
        ch_he_by_table = RUN_MOIRE.out.he_summary

        if ('moire' in coi_methods) {
            STANDARDIZE_COI_MOIRE(RUN_MOIRE.out.coi_summary, 'moire')
            ch_versions = ch_versions.mix(STANDARDIZE_COI_MOIRE.out.versions)
            ch_coi_by_method = ch_coi_by_method.mix(STANDARDIZE_COI_MOIRE.out.coi_table)

            ADD_POP_COI_SUMMARY(RUN_MOIRE.out.coi_summary.map(remap_pop), ch_lookup)
            ch_versions = ch_versions.mix(ADD_POP_COI_SUMMARY.out.versions)
            CONCAT_MOIRE_COI(ADD_POP_COI_SUMMARY.out.labeled_table.collect(), 'moire_coi_summary.tsv')
            ch_versions = ch_versions.mix(CONCAT_MOIRE_COI.out.versions)

            ADD_POP_EFFECTIVE_COI(RUN_MOIRE.out.effective_coi_summary.map(remap_pop), ch_lookup)
            ch_versions = ch_versions.mix(ADD_POP_EFFECTIVE_COI.out.versions)
            CONCAT_EFFECTIVE_COI(ADD_POP_EFFECTIVE_COI.out.labeled_table.collect(), 'effective_coi_summary.tsv')
            ch_versions = ch_versions.mix(CONCAT_EFFECTIVE_COI.out.versions)

            ADD_POP_CONVERGENCE(RUN_MOIRE.out.convergence_summary.map(remap_pop), ch_lookup)
            ch_versions = ch_versions.mix(ADD_POP_CONVERGENCE.out.versions)
            CONCAT_CONVERGENCE(ADD_POP_CONVERGENCE.out.labeled_table.collect(), 'convergence_summary.tsv')
            ch_versions = ch_versions.mix(CONCAT_CONVERGENCE.out.versions)
        }

        if (!params.skip_allele_frequencies) {
            ADD_POP_ALLELE_FREQ(RUN_MOIRE.out.allele_freq_summary.map(remap_pop), ch_lookup)
            ch_versions = ch_versions.mix(ADD_POP_ALLELE_FREQ.out.versions)
            CONCAT_ALLELE_FREQ(ADD_POP_ALLELE_FREQ.out.labeled_table.collect(), 'allele_freq_summary.tsv')
            ch_versions = ch_versions.mix(CONCAT_ALLELE_FREQ.out.versions)
        }

        ADD_POP_HE(RUN_MOIRE.out.he_summary.map(remap_pop), ch_lookup)
        ch_versions = ch_versions.mix(ADD_POP_HE.out.versions)
        CONCAT_HE(ADD_POP_HE.out.labeled_table.collect(), 'he_summary.tsv')
        ch_versions = ch_versions.mix(CONCAT_HE.out.versions)

        if (!params.skip_within_host_relatedness) {
            ADD_POP_WITHIN_HOST(RUN_MOIRE.out.relatedness_summary.map(remap_pop), ch_lookup)
            ch_versions = ch_versions.mix(ADD_POP_WITHIN_HOST.out.versions)
            CONCAT_WITHIN_HOST(ADD_POP_WITHIN_HOST.out.labeled_table.collect(), 'within_host_summary.tsv')
            ch_versions = ch_versions.mix(CONCAT_WITHIN_HOST.out.versions)
        }
    }

    if (!params.skip_coi) {
        ADD_POP_COI_TABLE(
            ch_coi_by_method.map { pop_index, _method, table ->
                has_population_assignment ? [pop_index, table] : [params.population_label, table]
            },
            ch_lookup
        )
        ch_versions = ch_versions.mix(ADD_POP_COI_TABLE.out.versions)
        CONCAT_COI_SUMMARY(ADD_POP_COI_TABLE.out.labeled_table.collect(), 'coi_summary.tsv')
        ch_versions = ch_versions.mix(CONCAT_COI_SUMMARY.out.versions)

        COUNT_SAMPLES_BY_COI(ch_coi_by_method)
        ch_versions = ch_versions.mix(COUNT_SAMPLES_BY_COI.out.versions)
        ADD_POP_SAMPLE_COUNT(COUNT_SAMPLES_BY_COI.out.sample_count_per_coi.map(remap_pop), ch_lookup)
        ch_versions = ch_versions.mix(ADD_POP_SAMPLE_COUNT.out.versions)
        CONCAT_SAMPLE_COUNT(ADD_POP_SAMPLE_COUNT.out.labeled_table.collect(), 'sample_count_per_coi.tsv')
        ch_versions = ch_versions.mix(CONCAT_SAMPLE_COUNT.out.versions)
    }

    //
    // Between-host relatedness (Dcifer)
    //
    if (!params.skip_between_host_relatedness) {
        DCIFER_IBD(ch_allele_for_tools)
        ch_versions = ch_versions.mix(DCIFER_IBD.out.versions)

        ADD_POP_BETWEEN_HOST(DCIFER_IBD.out.btwn_host_rel.map(remap_pop), ch_lookup)
        ch_versions = ch_versions.mix(ADD_POP_BETWEEN_HOST.out.versions)
        CONCAT_BETWEEN_HOST(ADD_POP_BETWEEN_HOST.out.labeled_table.collect(), 'between_host_summary.tsv')
        ch_versions = ch_versions.mix(CONCAT_BETWEEN_HOST.out.versions)
    }

    //
    // Per-target summaries → merge columns → label → concat
    //
    if (!params.skip_per_target_summaries) {
        ALLELE_PER_LOCUS_SUMMARY(ch_allele_for_tools)
        ch_versions = ch_versions.mix(ALLELE_PER_LOCUS_SUMMARY.out.versions)

        PER_LOCUS_POPGEN_SUMMARY(ch_allele_for_tools)
        ch_versions = ch_versions.mix(PER_LOCUS_POPGEN_SUMMARY.out.versions)

        MERGE_PER_LOCUS_SUMMARY(
            ALLELE_PER_LOCUS_SUMMARY.out.allele_summary_by_target
                .join(PER_LOCUS_POPGEN_SUMMARY.out.per_locus_popgen_summary)
                .join(ch_he_by_table, remainder: true)
                .map { prefix, allele_summary, popgen_summary, he_summary ->
                    [prefix, allele_summary, popgen_summary, he_summary ?: []]
                }
        )
        ch_versions = ch_versions.mix(MERGE_PER_LOCUS_SUMMARY.out.versions)

        ADD_POP_PER_TARGET(MERGE_PER_LOCUS_SUMMARY.out.per_target_summary.map(remap_pop), ch_lookup)
        ch_versions = ch_versions.mix(ADD_POP_PER_TARGET.out.versions)
        CONCAT_PER_TARGET(ADD_POP_PER_TARGET.out.labeled_table.collect(), 'per_target_summary.tsv')
        ch_versions = ch_versions.mix(CONCAT_PER_TARGET.out.versions)
    }

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
    multiqc_report   = ch_multiqc_report
    unassigned_count = ch_unassigned_count
    versions         = ch_versions
}
