# nf-core/eupathpopgen: Changelog

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/)
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## v1.0.0dev - [unreleased]

Initial release of nf-core/eupathpopgen.

nf-core/eupathpopgen estimates population-genetic metrics from microhaplotype data for eukaryotic pathogens (for example _Plasmodium_). Infections are often polyclonal, so the workflow is organised around estimates rather than tools: complexity of infection (COI), allele frequencies, within-host relatedness, between-host IBD, and per-target diversity summaries.

Input is either a PGEcore allele table or a Portable Microhaplotype Object (PMO). Samples can be analysed as one group or split by a user-supplied population assignment (or PMO specimen metadata). COI can be estimated with a naive method, MOIRE, or both. Allele frequencies and within-host relatedness currently come from MOIRE; between-host relatedness from Dcifer. Per-target allele-count and popgen summaries always run. Results are published as concatenated tables with a leading `population` column (`coi/`, `relatedness/`, `raw_outputs/`). `-profile plasmodium` applies Plasmodium-validated defaults.
