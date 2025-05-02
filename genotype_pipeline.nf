#!/usr/bin/env nextflow

/*
 * Genotype Pipeline for UK Biobank Data
 * This pipeline performs:
 * 1. Merging of chromosome-wise genotype files
 * 2. SNP QC and pruning
 */

// Default parameters
params {
    // Input parameters
    gt_dir = "path/to/genotype/files"
    rel_rsid = "path/to/rel_rsid.txt"
    output_dir = "results"
    
    // QC parameters
    mac = 100
    maf = 0.01
    hwe = 1e-15
    mind = 0.1
    geno = 0.1
    
    // DNA Nexus parameters
    dx_instance = "mem1_ssd1_v2_x16"
}

// Process to merge chromosome files
process mergeChromosomes {
    publishDir "${params.output_dir}/merged", mode: 'copy'
    
    input:
    path "*_c{1..22}_b0_v2.{bed,bim,fam}" from ch_input_files
    path rel_rsid from params.rel_rsid
    path "scripts/geno_merge.sh" from "${projectDir}/scripts/geno_merge.sh"
    
    output:
    path "ukb22418_merged_c1_22_v2_merged.{bed,bim,fam}" into merged_files
    
    script:
    """
    # Set environment variables for the script
    export gt_dir="${params.gt_dir}"
    export user_dir="${params.output_dir}"
    export rel_rsid="${rel_rsid}"
    
    # Run the merge script
    bash scripts/geno_merge.sh
    """
}

// Process to perform QC
process performQC {
    publishDir "${params.output_dir}/qc", mode: 'copy'
    
    input:
    path "ukb22418_merged_c1_22_v2_merged.{bed,bim,fam}" from merged_files
    path "scripts/perform_qc.sh" from "${projectDir}/scripts/perform_qc.sh"
    
    output:
    path "ukb22418_merged_c1_22_v2_merged_qc_pruned.{bed,bim,fam}"
    
    script:
    """
    # Set environment variables for the script
    export mac=${params.mac}
    export maf=${params.maf}
    export hwe=${params.hwe}
    export mind=${params.mind}
    export geno=${params.geno}
    export user_dir="${params.output_dir}"
    
    # Run the QC script
    bash scripts/perform_qc.sh ukb22418_merged_c1_22_v2_merged
    """
}

// Workflow
workflow {
    // Create channel for input files
    ch_input_files = Channel
        .fromPath("${params.gt_dir}/ukb22418_c*_b0_v2.{bed,bim,fam}")
        .map { file -> tuple(file.baseName, file) }
        .groupTuple()
        .map { name, files -> files }
    
    // Run processes
    mergeChromosomes()
    performQC()
} 