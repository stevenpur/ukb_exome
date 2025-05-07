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
// Process to filter 90pct10dp variants
process FILTER_90PCT10DP {
    publishDir "${params.work_dir}", mode: 'copy'

    input:
    val chr

    output:
    tuple val(chr), file("90pct10dp_results_c${chr}.txt")
    script:
    """
    python ${params.code_dir}/90pct10dp.py \
        --exome_dir "${params.exome_dir}" \
        --exome_helper_dir "${params.exome_helper_dir}" \
        --filter_90pct10dp_name "${params.filter_90pct10dp_name}" \
        --output_dir "${params.output_dir}" \
        --chr ${chr}
    """
}

process CHR_GT_MERGE {
    publishDir "${params.work_dir}", mode: 'copy'

    input:
    val chrs
    
    output:
    file "merged_results.txt"
    
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
    file "qc_results.txt"
    
    script:
    """
    sh ${params.code_dir}/snp_qc.sh \
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
    file "regenie_step1_results.txt"
    
    script:
    """
    sh ${params.code_dir}/regenie_step1.sh \
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
    tuple val(chr), file(exome_qc_results)

    output:
    file("regenie_step2_results_c${chr}.txt")
    
    script:
    """
    python ${params.code_dir}/regenie_step2.py \
        --regenie_step1_results ${step1_output_results} \
        --exome_qc_results ${exome_qc_results} \
        --exome_helper_dir "${params.exome_helper_dir}" \
        --pheno_desc ${pheno_desc_file} \
        --out_dir ${params.output_dir} \
        --chr ${chr}
    """
}


// Main workflow
workflow {
    ch_pheno_desc_file = Channel.value(file(params.pheno_desc_file))
    // Create channel for chromosomes
    ch_chromosomes = Channel.of(21, 22)
    
    ch_exome_qc = FILTER_90PCT10DP(ch_chromosomes)
    
    ch_merged_gt = CHR_GT_MERGE(ch_chromosomes
        .collect()
        .map { chromosomes -> chromosomes.join(',') }
    )
    
    ch_snp_qc = SNP_QC(ch_merged_gt, ch_pheno_desc_file)

    ch_regenie_step1 = REGENIE_STEP1(ch_snp_qc, ch_pheno_desc_file)

    ch_regenie_step2 = REGENIE_STEP2(ch_regenie_step1, ch_pheno_desc_file, ch_exome_qc)
}

 