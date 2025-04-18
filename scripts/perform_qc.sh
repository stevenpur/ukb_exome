#!/bin/bash

# Check if input argument is provided
if [ $# -ne 1 ]; then
    echo "Usage: $0 <input_plink_prefix>"
    echo "Example: $0 ukb22418_merged_c1_22_v2_merged"
    exit 1
fi

# Get input plink prefix
input_plink=$1

# Construct PLINK command
plink_cmd="plink --bfile ${input_plink} \
    --mac ${mac} \
    --maf ${maf} \
    --hwe ${hwe} \
    --mind ${mind} \
    --geno ${geno} \
    --indep-pairwise 1000 100 0.9 \
    --make-bed \
    --out ${input_plink}_qc && \
    plink --bfile ${input_plink}_qc \
    --extract ${input_plink}_qc.prune.in \
    --make-bed \
    --out ${input_plink}_qc_pruned"

# Run command with dx
dx run swiss-army-knife \
    -iin="${input_plink}.bim" \
    -iin="${input_plink}.fam" \
    -iin="${input_plink}.bed" \
    -icmd="$plink_cmd" \
    --destination "${user_dir}" \
    --name perform_qc_chr${chr} \
    --tag perform_qc_chr${chr} \
    --yes \
    --watch 