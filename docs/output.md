# nf-core/eupathpopgen: Output

## Introduction

Results are written under `--outdir`. Estimate tables are mostly at the top level and include a leading `population` column. Raw MOIRE heterozygosity is kept under `raw_outputs/`; relatedness files sit directly under `relatedness/`.

When `--population_assignment` (or PMO population fields) is set, each population is analysed in parallel under a stable `popidx_NNN` key, then labeled and concatenated into these final summaries.

## Output layout

```
outdir/
├── coi_table.tsv                 # always; one row per sample per COI method
├── sample_count_per_coi.tsv      # always; COI sample counts per COI method
├── coi_summary.tsv               # when --coi_method includes moire (full MOIRE posterior)
├── effective_coi_summary.tsv     # when --coi_method includes moire
├── convergence_summary.tsv       # when --coi_method includes moire
├── allele_freq_summary.tsv       # unless --skip_allele_frequencies
├── per_locus_summary.tsv         # always (allele counts + popgen; + he when MOIRE ran)
├── raw_outputs/
│   └── he_summary.tsv            # when MOIRE ran (full HE table only)
├── relatedness/
│   ├── within_host.tsv           # unless --skip_within_host_relatedness
│   └── between_host.tsv          # unless --skip_between_host_relatedness
├── unassigned_specimens.txt      # only when some specimens are missing from the population assignment
├── multiqc/
└── pipeline_info/
    └── pmo/                      # extracted allele_table / population assignment when --pmo
```

## Grain (what each row is)

| File                                            | Grain                                                                                                                                             |
| ----------------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------- |
| `coi_table.tsv`                                 | **Per sample × COI method** (`specimen_name`, `coi_method`) within each `population` — columns `population`, `coi_method`, `specimen_name`, `coi` |
| `coi_summary.tsv` / `effective_coi_summary.tsv` | **Per sample** (`specimen_name`) within each `population`                                                                                         |
| `relatedness/within_host.tsv`                   | **Per sample** within each `population`                                                                                                           |
| `relatedness/between_host.tsv`                  | **Per sample pair** (`specimen_name_a`, `specimen_name_b`) within each `population`                                                               |
| `sample_count_per_coi.tsv`                      | Per COI method × COI value (counts of samples) within each `population`                                                                           |
| `allele_freq_summary.tsv`                       | Per locus × allele (`target_name`, `seq`) within each `population` — columns start `population`, `target_name`, `seq`, `freq`, then CI/other      |
| `per_locus_summary.tsv`                         | **Per locus** (`target_name`) within each `population`                                                                                            |
| `raw_outputs/he_summary.tsv`                    | **Per locus** within each `population`                                                                                                            |
| `convergence_summary.tsv`                       | Run-level per `population`                                                                                                                        |

## Notes

- Every published estimate table starts with a `population` column. Single-population runs use `--population_label` (default `pop1`).
- `per_locus_summary.tsv` merges allele-count and popgen columns on `target_name`. When MOIRE runs, it also adds `he` (posterior mean expected heterozygosity).
- Allele frequencies and within-host relatedness currently come from MOIRE; between-host relatedness from Dcifer.
- MOIRE runs at most once per allele table / population split even when it supplies several estimates.
- `--coi_method` accepts a comma-separated list (e.g. `naive,moire`). Every requested method contributes rows to `coi_table.tsv` and `sample_count_per_coi.tsv`, distinguished by `coi_method`. For MOIRE, `coi` is the posterior mean; `sample_count_per_coi.tsv` rounds it to the nearest integer.
- When `--coi_method` does not include `moire`, MOIRE COI files are not published (even if MOIRE ran for allele frequencies / relatedness).
- `unassigned_specimens.txt` lists specimens in the allele table that are missing from the population assignment (`--population_assignment` or `--pmo_population_fields`), one per line. These specimens are excluded from all population-level outputs. It is only written when at least one specimen is unassigned, in which case the pipeline also logs a warning with the number of excluded specimens (mid-run and again after completion).
- `he_summary.tsv` is published only under `raw_outputs/` (not at the results root).
