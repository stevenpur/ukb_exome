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
    
    output:
    path "ukb22418_merged_c1_22_v2_merged.{bed,bim,fam}" into merged_files
    
    script:
    """
    # Create merge list
    for chr in {1..22}
    do
        plink_cmd="plink --bfile ukb22418_c\${chr}_b0_v2 \\
            --extract ${rel_rsid} \\
            --make-bed \\
            --out ukb22418_c\${chr}_rel"
            
        dx run swiss-army-knife \
            -iin=ukb22418_c\${chr}_b0_v2.bed \
            -iin=ukb22418_c\${chr}_b0_v2.bim \
            -iin=ukb22418_c\${chr}_b0_v2.fam \
            -iin=${rel_rsid} \
            -icmd="\$plink_cmd" \
            --destination . \
            --instance-type ${params.dx_instance} \
            --yes
    done
    
    ls *_rel.bed | sed 's/.bed//g' > merge_list.txt
    
    merge_cmd="plink --merge-list merge_list.txt \\
        --make-bed \\
        --out ukb22418_merged_c1_22_v2_merged"
        
    dx run swiss-army-knife \
        -iin=merge_list.txt \
        -iin=*_rel.bed \
        -iin=*_rel.bim \
        -iin=*_rel.fam \
        -icmd="\$merge_cmd" \
        --destination . \
        --instance-type ${params.dx_instance} \
        --yes
    """
}

// Process to perform QC
process performQC {
    publishDir "${params.output_dir}/qc", mode: 'copy'
    
    input:
    path "ukb22418_merged_c1_22_v2_merged.{bed,bim,fam}" from merged_files
    
    output:
    path "ukb22418_merged_c1_22_v2_merged_qc.{bed,bim,fam}" into qc_files
    
    script:
    """
    plink --bfile ukb22418_merged_c1_22_v2_merged \\
        --mac ${params.mac} \\
        --maf ${params.maf} \\
        --hwe ${params.hwe} \\
        --mind ${params.mind} \\
        --geno ${params.geno} \\
        --make-bed \\
        --out ukb22418_merged_c1_22_v2_merged_qc
    """
}

// Process to perform LD pruning
process performPruning {
    publishDir "${params.output_dir}/pruned", mode: 'copy'
    
    input:
    path "ukb22418_merged_c1_22_v2_merged_qc.{bed,bim,fam}" from qc_files
    
    output:
    path "ukb22418_merged_c1_22_v2_merged_qc_pruned.{bed,bim,fam}"
    
    script:
    """
    plink --bfile ukb22418_merged_c1_22_v2_merged_qc \\
        --indep-pairwise 50 5 0.2 \\
        --out ukb22418_merged_c1_22_v2_merged_qc_pruned
    
    plink --bfile ukb22418_merged_c1_22_v2_merged_qc \\
        --extract ukb22418_merged_c1_22_v2_merged_qc_pruned.prune.in \\
        --make-bed \\
        --out ukb22418_merged_c1_22_v2_merged_qc_pruned
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
    performPruning()
} 