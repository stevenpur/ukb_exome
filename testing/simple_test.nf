#!/usr/bin/env nextflow

/*
 * Simple test pipeline for UK Biobank chromosome 1
 * This pipeline performs basic operations on chromosome 1 data
 */

// Default parameters
params {
    // Input parameters
    gt_dir = "/mnt/project/Bulk/Genotype Results/Genotype calls/"
    out_dir = "/mnt/project/users/steven"
}

// Process to perform basic QC on chromosome 1
process basicQC {
    publishDir "${params.out_dir}/", mode: 'copy'
    
    input:
    path "ukb22418_c1_b0_v2.{bed,bim,fam}" from ch_input_files
    
    output:
    path "ukb22418_c1_b0_v2_qc.{bed,bim,fam}" into qc_files
    
    script:
    """
    # Simple QC: remove SNPs with missing rate > 10%
    plink --bfile ukb22418_c1_b0_v2 \\
        --geno 0.1 \\
        --make-bed \\
        --out ukb22418_c1_b0_v2_qc
    """
}

// Process to calculate basic statistics
process calculateStats {
    publishDir "${params.out_dir}/", mode: 'copy'
    
    input:
    path "ukb22418_c1_b0_v2_qc.{bed,bim,fam}" from qc_files
    
    output:
    path "ukb22418_c1_b0_v2_qc_stats.txt"
    
    script:
    """
    # Calculate basic statistics
    plink --bfile ukb22418_c1_b0_v2_qc \\
        --freq \\
        --missing \\
        --hardy \\
        --out ukb22418_c1_b0_v2_qc_stats
    """
}

// Workflow
workflow {
    // Simple channel for chromosome 1 files
    ch_input_files = Channel.fromPath("${params.gt_dir}/ukb22418_c1_b0_v2.{bed,bim,fam}")
    // Run processes
    basicQC()
    calculateStats()
} 