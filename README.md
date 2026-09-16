# nf-core/eupathpopgen

[![GitHub Actions CI Status](https://github.com/nf-core/eupathpopgen/actions/workflows/nf-test.yml/badge.svg)](https://github.com/nf-core/eupathpopgen/actions/workflows/nf-test.yml)
[![GitHub Actions Linting Status](https://github.com/nf-core/eupathpopgen/actions/workflows/linting.yml/badge.svg)](https://github.com/nf-core/eupathpopgen/actions/workflows/linting.yml)
[![Nextflow](https://img.shields.io/badge/version-%E2%89%A525.10.4-green?style=flat&logo=nextflow&logoColor=white&color=%230DC09D&link=https%3A%2F%2Fnextflow.io)](https://www.nextflow.io/)

[![nf-core template version](https://img.shields.io/badge/nf--core_template-4.1.0-green?style=flat&logo=nfcore&logoColor=white&color=%2324B064&link=https%3A%2F%2Fnf-co.re)](https://github.com/nf-core/tools/releases/tag/4.1.0)
[![run with conda](http://img.shields.io/badge/run%20with-conda-3EB049?labelColor=000000&logo=anaconda)](https://docs.conda.io/en/latest/)
[![run with docker](https://img.shields.io/badge/run%20with-docker-0db7ed?labelColor=000000&logo=docker)](https://www.docker.com/)
[![run with singularity](https://img.shields.io/badge/run%20with-singularity-1d355c.svg?labelColor=000000)](https://sylabs.io/docs/)

## Introduction

**nf-core/eupathpopgen** estimates population-genetic metrics from **microhaplotype / allele-table** data for eukaryotic pathogens (for example *Plasmodium*). Infections are often polyclonal, so the pipeline focuses on COI, allele frequencies, within-host relatedness, between-host IBD, and per-locus summaries using [PGEcore](https://github.com/PlasmoGenEpi/PGEcore) and specialist tools (MOIRE, Dcifer).

The scientific methods are Plasmodium-validated; use `-profile plasmodium` for recommended defaults. The pipeline name is pathogen-agnostic so other eukaryotic pathogens can share the same workflow as methods mature.

## Pipeline summary

1. Optionally split the allele table by user-defined populations
2. Estimate COI with `--coi_method naive` or `moire`
3. Optionally estimate allele frequencies and within-host relatedness (MOIRE; single run when needed)
4. Optionally estimate between-host relatedness / IBD (Dcifer)
5. Always generate per-locus allele and popgen summaries
6. Collate software versions with MultiQC

## Quick start

```bash
nextflow run nf-core/eupathpopgen \
  -profile docker,plasmodium \
  --allele_table alleles.tsv \
  --outdir results
```

Allele tables must use PGEcore columns: `specimen_name`, `target_name`, `seq`, and usually `reads`.

### Developing against a local PGEcore checkout

While PGEcore is not yet on conda, CI installs a pinned GitHub commit. For local package development:

```bash
export PGECORE_HOME=/path/to/PGEcore
nextflow run . -profile conda,pgecore_local,test --outdir results
```

See [usage](docs/usage.md) for details.

## Credits

nf-core/eupathpopgen was originally written by Kathryn Murie and the PlasmoGenEpi Network.

## Citations

See [CITATIONS.md](CITATIONS.md).
