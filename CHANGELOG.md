# nf-core/eupathpopgen: Changelog

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/)
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## v1.0.0dev - [unreleased]

### `Added`

- Allele-table or PMO population genetics workflow organised around estimates (`--coi_method`, skip flags for AF / relatedness)
- Multiple COI methods in one run (`--coi_method naive,moire`), combined into `coi_table.tsv` / `sample_count_per_coi.tsv` with a `coi_method` column
- Optional PMO entry via `--pmo` (pmotools extract) with optional `--pmo_population_fields`
- Optional population split via `--population_assignment` (or PMO-derived map); parallel `popidx` runs are labeled and concatenated into final summaries. Specimens missing from the population assignment are listed in `unassigned_specimens.txt` and reported with a warning rather than dropped silently
- Flat estimate outputs under `--outdir` (no `COI/` or `allele_frequencies/` nesting); merged `per_locus_summary.tsv`
- `-profile plasmodium` with Plasmodium-validated defaults (naive COI, all AF / relatedness estimates on)
- Local copies of shared test inputs under `tests/input/` (canonical files live on the `eupathpopgen` branch of nf-core/test-datasets, reused from plasmodiumdrugres)

### `Dependencies`

- PGEcore 0.1.0 (`bioconda::r-pgecore`)
- pmotools 1.1.0 (`bioconda::pmotools`, PMO input)
- dcifer 1.5.2, pegas, ape, Biostrings, pwalign, msa, muscle 5.1 (conda)
- moire (not on conda; installed from GitHub at runtime)
