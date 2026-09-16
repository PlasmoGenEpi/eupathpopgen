# nf-core/eupathpopgen: Usage

## Introduction

Provide exactly one of:

- `--allele_table` — PGEcore allele-table TSV
- `--pmo` — [Portable Microhaplotype Object](https://plasmogenepi.github.io/PMO_Docs/) JSON (allele table extracted with pmotools)

Optional population stratification via `--population_map`, or (with `--pmo`) `--pmo_population_fields`.

## Allele table

Required columns (see [PGEcore input-formats](https://plasmogenepi.github.io/PGEcore/articles/input-formats.html)):

| Column | Description |
|--------|-------------|
| `specimen_name` | Sample / specimen ID |
| `target_name` | Locus / amplicon ID |
| `seq` | Allele sequence |
| `reads` | Read count (needed for naive COI and Dcifer) |

## PMO input

```bash
nextflow run nf-core/eupathpopgen \
  -profile docker,plasmodium \
  --pmo input.json \
  --pmo_population_fields "collection_country,collection_date" \
  --outdir results
```

- `--pmo_population_fields` — comma-separated specimen metadata fields joined into `population` labels
- `--pmo_population_separator` — join string (default `_`)
- `--population_map` — if set, overrides PMO-derived population labels

Extracted allele table / population map are published under `pipeline_info/pmo/`.

## Running the pipeline

```bash
nextflow run nf-core/eupathpopgen \
  -profile docker,plasmodium \
  --allele_table alleles.tsv \
  --outdir results
```

### Profiles

| Profile | Purpose |
|---------|---------|
| `plasmodium` | Plasmodium-validated defaults (`--coi_method moire`, all relatedness/AF estimates on) |
| `test` | Shared drugres allele table from test-datasets; naive COI only |
| `test_pmo` | Shared drugres example PMO (+ `collection_country` population fields); naive COI only |
| `test_full` | Allele table + population map; MOIRE COI + AF + relatedness (reduced MCMC) |
| `pgecore_local` | Use `PGECORE_HOME` source checkout instead of the GitHub pin |
| `docker` / `singularity` / `conda` / `wave` | Standard nf-core executors |

### Estimates (not tools)

| Parameter | Meaning |
|-----------|---------|
| `--coi_method` | `naive` or `moire` (COI is always estimated) |
| `--naive_coi_method` | `integer_method` or `quantile_method` when `--coi_method naive` |
| `--naive_coi_threshold` | Integer index or quantile in \[0, 1] |
| `--skip_allele_frequencies` | Skip allele-frequency outputs (currently from MOIRE) |
| `--skip_within_host_relatedness` | Skip within-host relatedness outputs (currently from MOIRE) |
| `--skip_between_host_relatedness` | Skip between-host IBD outputs (currently from Dcifer) |

Per-locus allele counts and popgen summaries always run.

MOIRE is invoked **at most once**. It runs when `--coi_method moire` and/or allele frequencies / within-host relatedness are requested. Skipped MOIRE-backed estimates are not published even if produced as intermediates.

### Test data

`-profile test` / `test_pmo` / `test_full` use inputs from the [`eupathpopgen` branch of test-datasets](https://github.com/kathrynmurie/test-datasets/tree/eupathpopgen) (shared with plasmodiumdrugres). After that branch is merged into [nf-core/test-datasets](https://github.com/nf-core/test-datasets), update `pipelines_testdata_base_path` in the test configs to `https://raw.githubusercontent.com/nf-core/test-datasets/`.

### Docker notes

`PER_LOCUS_POPGEN_SUMMARY` uses `bioconductor/bioconductor_docker` and installs `muscle` inside the container on first run (needs network). Prefer `-profile conda,pgecore_local` for faster local iteration.

### Local PGEcore development (`pgecore_local`)

```bash
export PGECORE_HOME=/path/to/PGEcore
nextflow run . \
  -profile conda,pgecore_local,test \
  --outdir results
```

### MOIRE / Dcifer tuning

Optional hidden `--moire_*` and `--dcifer_*` parameters map to PGEcore wrapper flags.

## Outputs

See [output.md](output.md).
