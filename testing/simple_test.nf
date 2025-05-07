#!/usr/bin/env nextflow

/*
 * Genotype Pipeline for UK Biobank Data
 * This pipeline performs:
 * 1. Merging of chromosome-wise genotype files
 * 2. SNP QC and pruning
 */

nextflow.enable.dsl=2

// Default parameters
// Input parameters
output_dir = "/users/steven/"
exome_dir = "/Bulk/Exome sequences/Population level exome OQFE variants, PLINK format - final release"
filter_90pct10dp_dir = "/Bulk/Exome sequences/Population level exome OQFE variants, PLINK format - final release/helper_files/"
filter_90pct10dp_name = "ukb23158_500k_OQFE.90pct10dp_qc_variants.txt"
// DNA Nexus parameters
dx_instance = "mem1_ssd1_v2_x16"
gt_dir = "/Bulk/Genotype Results/Genotype calls"

// a simple process that calculates the freq of a chromosome
process CHR_FREQ {
    publishDir "${HOME}/ukb_rap/ukb_exome/testing", mode: 'copy'

    input:
    val chr
    
    output:
    file "hello2.txt"
    
    script:
    """
    sh ${HOME}/ukb_rap/ukb_exome/testing/simple_freq.sh ${chr} ${exome_dir} ${output_dir} ${dx_instance}
    """
}


workflow {
    CHR_FREQ(21)
}