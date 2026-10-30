# nf-core/eupathpopgen: Output

## Introduction

Results are written under `--outdir`. Combined COI tables sit under `coi/`; relatedness under `relatedness/`. `raw_outputs/` holds tool tables that are not the same as the final processed summaries. Every estimate table includes a leading `population` column.

When `--population_assignment` (or PMO population fields) is set, each population is analysed in parallel under a stable `popidx_NNN` key, then labeled and concatenated into these final summaries.

## Output layout

```
outdir/
├── coi/
│   ├── coi_summary.tsv               # unless --skip_coi; one row per sample per COI method
│   ├── sample_count_per_coi.tsv      # unless --skip_coi; COI sample counts per COI method
│   └── effective_coi_summary.tsv     # unless --skip_coi, when --coi_method includes moire
├── allele_freq_summary.tsv           # unless --skip_allele_frequencies
├── per_target_summary.tsv            # unless --skip_per_target_summaries (allele counts + popgen; + he when MOIRE ran)
├── raw_outputs/
│   ├── moire_coi_summary.tsv         # when --coi_method includes moire (full MOIRE posterior)
│   ├── convergence_summary.tsv       # when --coi_method includes moire
│   └── he_summary.tsv                # when MOIRE ran (full HE table only)
├── relatedness/
│   ├── within_host_summary.tsv       # unless --skip_within_host_relatedness
│   └── between_host_summary.tsv      # unless --skip_between_host_relatedness
├── unassigned_specimens.txt          # only when some specimens are missing from the population assignment
├── multiqc/
└── pipeline_info/
    └── pmo/                          # extracted population assignment when --pmo_population_fields is set
```

## Grain (what each row is)

| File                                   | Grain                                                                                                                                                            |
| -------------------------------------- | ---------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `coi/coi_summary.tsv`                  | **Per sample** within each `population`. One method: `population`, `specimen_name`, `coi`. Several methods: wide (`population`, `specimen_name`, `coi_<method>`) |
| `coi/effective_coi_summary.tsv`        | **Per sample** (`specimen_name`) within each `population`                                                                                                        |
| `raw_outputs/moire_coi_summary.tsv`    | **Per sample** (`specimen_name`) within each `population` (full MOIRE posterior)                                                                                 |
| `relatedness/within_host_summary.tsv`  | **Per sample** within each `population`                                                                                                                          |
| `relatedness/between_host_summary.tsv` | **Per sample pair** (`specimen_name_a`, `specimen_name_b`) within each `population`                                                                              |
| `coi/sample_count_per_coi.tsv`         | Per COI method × COI value (counts of samples) within each `population`                                                                                          |
| `allele_freq_summary.tsv`              | Per target × allele (`target_name`, `seq`) within each `population` — columns start `population`, `target_name`, `seq`, `freq`, then CI/other                    |
| `per_target_summary.tsv`               | **Per target** (`target_name`) within each `population`                                                                                                          |
| `raw_outputs/he_summary.tsv`           | **Per target** within each `population`                                                                                                                          |
| `raw_outputs/convergence_summary.tsv`  | Run-level per `population`                                                                                                                                       |

## Notes

- Every published estimate table starts with a `population` column. Single-population runs use `--population_label` (default `pop1`).
- `--skip_coi` omits `coi/`. `--skip_per_target_summaries` omits `per_target_summary.tsv`. Setting every estimate skip flag is an error.
- `per_target_summary.tsv` merges allele-count and popgen columns on `target_name`. When MOIRE runs, it also adds `he` (posterior mean expected heterozygosity).
- Allele frequencies and within-host relatedness currently come from MOIRE; between-host relatedness from Dcifer.
- MOIRE runs at most once per allele table / population split even when it supplies several estimates.
- `--coi_method` accepts a comma-separated list (e.g. `naive,moire`). One method writes `coi/coi_summary.tsv` as `population`, `specimen_name`, `coi`. Several methods write one row per sample with `coi_<method>` columns (e.g. `coi_naive`, `coi_moire`). `sample_count_per_coi.tsv` stays long, distinguished by `coi_method`. For MOIRE, `coi` is the posterior mean; `sample_count_per_coi.tsv` rounds it to the nearest integer.
- When `--coi_method` does not include `moire`, MOIRE COI files are not published (even if MOIRE ran for allele frequencies / relatedness).
- Raw COI tables include the tool name (e.g. `moire_coi_summary.tsv`). Naive COI is not copied to `raw_outputs/` because it matches the processed `coi/coi_summary.tsv` rows.
- `unassigned_specimens.txt` lists specimens in the allele table that are missing from the population assignment (`--population_assignment` or `--pmo_population_fields`), one per line. These specimens are excluded from all population-level outputs. It is only written when at least one specimen is unassigned, in which case the pipeline also logs a warning with the number of excluded specimens (mid-run and again after completion).
- `moire_coi_summary.tsv`, `convergence_summary.tsv`, and `he_summary.tsv` are published only under `raw_outputs/`.
