# nf-core/eupathpopgen: Changelog

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/)
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## v1.0.0dev - [unreleased]

### `Added`

- Allele-table or PMO population genetics workflow organised around estimates (`--coi_method`, skip flags for AF / relatedness)
- Multiple COI methods in one run (`--coi_method naive,moire`), combined into a wide `coi/coi_summary.tsv` (`coi_naive`, `coi_moire`, …); `sample_count_per_coi.tsv` stays long with a `coi_method` column
- Optional PMO entry via `--pmo` (pmotools extract) with optional `--pmo_population_fields`
- Optional population split via `--population_assignment` (or PMO-derived map); parallel `popidx` runs are labeled and concatenated into final summaries. Specimens missing from the population assignment are listed in `unassigned_specimens.txt` and reported with a warning rather than dropped silently
- Estimate outputs grouped as `coi/` (combined `coi_summary.tsv`, effective COI, sample counts), `relatedness/`, and `raw_outputs/` (tool tables that differ from the finals, including `moire_coi_summary.tsv`); merged `per_target_summary.tsv`
- `-profile plasmodium` with Plasmodium-validated defaults (naive COI, all AF / relatedness estimates on)
- Local copies of shared test inputs under `tests/input/` (canonical files live on the `eupathpopgen` branch of nf-core/test-datasets, reused from plasmodiumdrugres)

### `Dependencies`

- PGEcore 0.1.0 (`bioconda::r-pgecore`)
- pmotools 1.1.0 (`bioconda::pmotools`, PMO input)
- moire 3.7.0 (`conda-forge::r-moire`)
- dcifer 1.5.2, pegas, ape, Biostrings, pwalign, msa, muscle 5.3 (conda)
