# UKB Exome Analysis Pipeline

A Nextflow pipeline for running genome-wide association studies (GWAS) on UK Biobank exome sequencing data using REGENIE on the Research Analysis Platform (RAP).

## Overview

This pipeline performs:
1. **Genotype QC** - Merges chromosomal data and applies quality control filters
2. **Association Testing** - Runs REGENIE two-step analysis for exome variants
3. **Post-processing** - Prepares results for downstream analysis including BHR and visualization

## Quick Start

### 1. Configure Parameters
Edit `config.sh` to set your data paths and output directories.

### 2. Run Genotype Pipeline
```bash
nextflow run genotype_pipeline.nf
```

### 3. Run ExomeWAS Analysis
```bash
nextflow run exomWAS_pipeline/exome_was.nf \
    --pheno_desc_file your_phenotypes.txt \
    --output_dir results/
```

## Pipeline Components

- **`genotype_pipeline.nf`** - Chromosome merging and SNP QC
- **`exomWAS_pipeline/`** - Main REGENIE association analysis
- **`postanalysis/`** - BHR preprocessing and result processing
- **`scripts/`** - Utility scripts for data management

## Requirements

- Nextflow
- Access to UK Biobank RAP
- Python 3.x with pandas, numpy
- R with required packages
- REGENIE software

## Output

The pipeline generates:
- Association statistics per chromosome
- QC metrics and logs
- BHR-ready formatted files
- Manhattan plots and visualizations

## Support

For issues or questions about this pipeline, please refer to the individual README files in each subdirectory for detailed usage instructions.