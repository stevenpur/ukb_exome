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

process CHR_GT_MERGE {
    publishDir "${params.work_dir}", mode: 'copy'

    input:
    val chrs
    
    output:
    file "merged_results.json"
    
    script:
    """
    python ${params.code_dir}/chr_merge.py \
        --chrs ${chrs} \
        --gt_dir "${params.gt_dir}" \
        --output_dir "${params.output_dir}" \
        --dx_instance "${params.dx_instance}"
    """
}

process SNP_QC {
    publishDir "${params.work_dir}", mode: 'copy'

    input:
    file merged_results_file
    file pheno_desc_file
    
    output:
    file "qc_results.json"
    
    script:
    """
    echo "output_dir: ${params.output_dir}"
    python ${params.code_dir}/snp_qc.py \
        --merged_results ${merged_results_file} \
        --pheno_desc ${pheno_desc_file} \
        --output_dir ${params.output_dir}
    """
}

process REGENIE_STEP1 {
    publishDir "${params.work_dir}", mode: 'copy'

    input:
    file gt_input_files
    file pheno_desc_file
    
    output:
    file "regenie_step1_results.json"
    
    script:
    """
    python ${params.code_dir}/regenie_step1.py \
        --gt_input_files ${gt_input_files} \
        --pheno_desc ${pheno_desc_file} \
        --output_dir ${params.output_dir}
    """
}

process REGENIE_STEP2 {
    publishDir "${params.work_dir}", mode: 'copy'

    input:
    file step1_output_results
    file pheno_desc_file
    val chr

    output:
    file("regenie_step2_results_c${chr}.txt")
    
    script:
    """
    python ${params.code_dir}/regenie_step2.py \
        --regenie_step1_results ${step1_output_results} \
        --exome_dir "${params.exome_dir}" \
        --exome_helper_dir "${params.exome_helper_dir}" \
        --pheno_desc ${pheno_desc_file} \
        --out_dir ${params.output_dir} \
        --chr ${chr}
    """
}


// Main workflow
workflow {
    // Input channels
    pheno_desc_channel = Channel.value(file(params.pheno_desc_file))
    chromosome_channel = Channel.of(1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22)
    
    
    // Merge chromosomes into a single string for GT merge
    merged_chromosomes_channel = chromosome_channel
        .collect()
        .map { chromosomes -> chromosomes.join(',') }
    
    // Execute remaining processes
    merged_gt_channel = CHR_GT_MERGE(merged_chromosomes_channel)
    snp_qc_channel = SNP_QC(merged_gt_channel, pheno_desc_channel)
    regenie_step1_channel = REGENIE_STEP1(snp_qc_channel, pheno_desc_channel)
    regenie_step2_channel = REGENIE_STEP2(regenie_step1_channel, pheno_desc_channel, chromosome_channel)
}

 