# nf-core/eupathpopgen: Usage

## Introduction

Provide exactly one of:

- `--allele_table` — PGEcore allele-table TSV
- `--pmo` — [Portable Microhaplotype Object](https://plasmogenepi.github.io/PMO_Docs/) JSON (allele table extracted with pmotools)

Optional population stratification via `--population_assignment`, or (with `--pmo`) `--pmo_population_fields`. Without either, all samples are analysed as one group labelled by `--population_label` (default `pop1`).

![nf-core/eupathpopgen metro map](images/nf-core-eupathpopgen_metromap.png)

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
- `--population_assignment` — if set, overrides PMO-derived population labels
- `--population_label` — single-population label when no assignment is provided (default `pop1`)

Extracted allele table / population assignment are published under `pipeline_info/pmo/`.

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
| `plasmodium` | Plasmodium-validated defaults (`--coi_method naive`, all relatedness/AF estimates on) |
| `test` | Shared drugres allele table from test-datasets; naive COI only |
| `test_pmo` | Shared drugres example PMO (+ `collection_country` population fields); naive COI only |
| `test_full` | Allele table + population assignment; MOIRE COI + AF + relatedness (reduced MCMC) |
| `pgecore_local` | Use `PGECORE_HOME` source checkout instead of the bioconda `r-pgecore` package |
| `docker` / `singularity` / `conda` / `wave` | Standard nf-core executors |

### Estimates (not tools)

| Parameter | Meaning |
|-----------|---------|
| `--coi_method` | `naive`, `moire`, or a comma-separated list such as `naive,moire` (COI is always estimated; multiple methods are combined into one table with a `coi_method` column) |
| `--naive_coi_method` | `integer_method` or `quantile_method` when `--coi_method` includes `naive` |
| `--naive_coi_threshold` | Integer index or quantile in \[0, 1] |
| `--skip_allele_frequencies` | Skip allele-frequency outputs (currently from MOIRE) |
| `--skip_within_host_relatedness` | Skip within-host relatedness outputs (currently from MOIRE) |
| `--skip_between_host_relatedness` | Skip between-host IBD outputs (currently from Dcifer) |

Per-locus allele counts and popgen summaries always run.

MOIRE is invoked **at most once**. It runs when `--coi_method` includes `moire` and/or allele frequencies / within-host relatedness are requested. Skipped MOIRE-backed estimates are not published even if produced as intermediates.

### Test data

`-profile test` / `test_pmo` / `test_full` use inputs from the [`eupathpopgen` branch of nf-core/test-datasets](https://github.com/nf-core/test-datasets/tree/eupathpopgen) (shared with plasmodiumdrugres).

### Software notes

All tools come from conda (bioconda / conda-forge) or matching Seqera community containers, with two exceptions that are installed at runtime (needs network):

- MOIRE is not on conda, so `RUN_MOIRE` installs it from GitHub into the task work directory.
- `bioconductor-msa` has no osx-arm64 conda build, so on Apple Silicon with `-profile conda`, `PER_LOCUS_POPGEN_SUMMARY` installs it via BiocManager. The containers already include it.

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
