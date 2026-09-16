# nf-core/eupathpopgen: Output

## Introduction

Results are written under `--outdir`, organised by **estimate** (not by tool).

## Output layout

```
outdir/
├── COI/
│   ├── naive/                 # when --coi_method naive
│   │   ├── coi_table.tsv
│   │   └── sample_count_per_coi.tsv
│   └── moire/                 # when --coi_method moire
│       ├── coi_summary.tsv
│       ├── effective_coi_summary.tsv
│       ├── convergence_summary.tsv
│       └── sample_count_per_coi.tsv
├── allele_frequencies/        # unless --skip_allele_frequencies
│   ├── allele_freq_summary.tsv
│   └── he_summary.tsv
├── relatedness/
│   ├── within_host/           # unless --skip_within_host_relatedness
│   │   └── relatedness_summary.tsv
│   └── between_host/          # unless --skip_between_host_relatedness
│       └── btwn_host_rel.tsv
├── per_locus_summaries/       # always
│   ├── allele_counts/
│   │   └── allele_summary_by_target.tsv
│   └── popgen/
│       └── per_locus_popgen_summary.tsv
├── populations/               # when --population_map or PMO population fields are set
├── multiqc/
└── pipeline_info/
    └── pmo/                   # extracted allele_table / population_map when --pmo
```

## Notes

- Allele frequencies and within-host relatedness currently come from MOIRE; between-host relatedness from Dcifer.
- MOIRE runs at most once per allele table / population split even when it supplies several estimates.
