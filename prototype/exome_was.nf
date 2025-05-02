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
gt_dir = "/Bulk/Genotype Results/Genotype calls"
// DNA Nexus parameters
dx_instance = "mem1_ssd1_v2_x16"

// Process to filter 90pct10dp variants
process FILTER_90PCT10DP {
    input:
    val chr
    
    script:
    """
    # Construct PLINK command to filter variants
    plink_cmd="plink --bfile ukb23158_c${chr}_b0_v1 \
        --extract ${filter_90pct10dp_name} \
        --make-bed \
        --out ukb23158_c${chr}_b0_v1_filtered"
    
    # Run command with dx swiss-army-knife
    dx run swiss-army-knife \
        -iin="${exome_dir}/ukb23158_c${chr}_b0_v1.bed" \
        -iin="${exome_dir}/ukb23158_c${chr}_b0_v1.bim" \
        -iin="${exome_dir}/ukb23158_c${chr}_b0_v1.fam" \
        -iin="${filter_90pct10dp_dir}/${filter_90pct10dp_name}" \
        -icmd="\${plink_cmd}" \
        --destination "${output_dir}/" \
        --instance-type ${dx_instance} \
        --yes
    """
}

process CHR_GT_MERGE {
    publishDir "${HOME}/ukb_rap/ukb_exome/testing", mode: 'copy'

    input:
    val chrs
    
    output:
    file "merged_results.txt"
    
    script:
    """
    python ${HOME}/ukb_rap/ukb_exome/scripts/chr_merge.py ${chrs} ${gt_dir} ${output_dir} ${dx_instance}
    """
}

process SNP_QC {
    publishDir "${HOME}/ukb_rap/ukb_exome/testing", mode: 'copy'

    input:
    file "merged_results.txt"
    
    output:
    file "qc_results.txt"
    
    script:
    """
    # get the prefix from merged_result.txt
    prefix=$(tail -n 1 merged_results.txt)
    merged_dir=$(head -n 1 merged_results.txt)
    plink_cmd="plink --bfile ${prefix} \
        --mac 10 \
        --maf 0.01 \
        --mind 0.01 \
        --geno 0.01 \
        --hwe 0.00001 \
        --indep 50 5 2 \
        --make-bed \
        --out ${prefix}_qc
        plink --bfile ${prefix}_qc \
            --extract ${prefix}_qc.prune.in \
            --make-bed \
            --out ${prefix}_qc_pruned"

    # Run command with dx swiss-army-knife
    dx run swiss-army-knife \
        -iin="${merged_dir}/${prefix}.bed" \
        -iin="${merged_dir}/${prefix}.bim" \
        -iin="${merged_dir}/${prefix}.fam" \
        -icmd="\${plink_cmd}" \
        --destination "${output_dir}/" \
        --wait
    exit_code=\$?
    if [ \$exit_code -ne 0 ]; then
        echo "Error: qc failed" > qc_results.txt
    else
        echo ${output_dir} > qc_results.txt
        echo ${prefix}_qc_pruned >> qc_results.txt
    fi
    """
}

// Main workflow
workflow {
    // Create channel for chromosomes
    ch_chromosomes = Channel.of(21, 22)
    
    // Run the filter process
    FILTER_90PCT10DP(ch_chromosomes)
    
    // Collect all chromosomes into a single value before merging
    ch_chromosomes
        .collect()
        .map { chromosomes -> chromosomes.join(' ') }
        | CHR_GT_MERGE
        | SNP_QC
}

 