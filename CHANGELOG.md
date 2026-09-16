# nf-core/eupathpopgen: Changelog

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/)
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## v1.0.0dev - [unreleased]

### `Added`

- Allele-table population genetics workflow organised around estimates (`--coi_method`, skip flags for AF / relatedness)
- Optional population split via `--population_map`
- `-profile plasmodium` with Plasmodium-validated defaults (`coi_method=moire`)
- PGEcore GitHub pin (`conf/pgecore.config`) and `-profile pgecore_local` for parallel package development
- Local copies of shared test inputs under `tests/input/` (canonical files live on the `eupathpopgen` branch of nf-core/test-datasets, reused from plasmodiumdrugres)

### `Dependencies`

- PGEcore (GitHub pin until conda publication)
- moire, dcifer, pegas (via module environments / runtime install)

### Conda cutover (when PGEcore is published)

1. Add `r-pgecore` (or equivalent) to each module `environment.yml`
2. Remove `bin/ensure_pgecore.R` GitHub install from module scripts
3. Regenerate Wave containers / conda lock files
4. Keep `pgecore_local` for maintainers iterating on unreleased PGEcore
