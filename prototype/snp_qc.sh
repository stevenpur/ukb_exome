#!/bin/bash

# get the prefix from merged_result.txt
while [[ $# -gt 0 ]]; do
    case $1 in
        --merged_results)
            merged_results_file="$2"
            shift 2
            ;;
        --pheno_desc)
            pheno_results_file="$2"
            shift 2
            ;;
        --output_dir)
            output_dir="$2"
            shift 2
            ;;
        *)
            echo "Unknown parameter: $1"
            exit 1
            ;;
    esac
done

merged_prefix=$(tail -n 1 ${merged_results_file})
merged_dir=$(head -n 1 ${merged_results_file})

pheno_dir=$(head -n 1 ${pheno_results_file})
pheno_file=$(tail -n 2 ${pheno_results_file} | head -n 1)


echo "merged_prefix: ${merged_prefix}"
echo "merged_dir: ${merged_dir}"
echo "output_dir: ${output_dir}"

plink_cmd="
    # Get list of individuals to keep from phenotype file
    awk 'NR>1 {print \$1\" \"\$2}' ${pheno_file} > keep.txt

    plink --bfile ${merged_prefix} \
    --keep keep.txt \
    --mac 100 \
    --maf 0.01 \
    --mind 0.1 \
    --geno 0.1 \
    --hwe 1e-15 \
    --indep 50 5 2 \
    --make-bed \
    --out ${merged_prefix}_qc

    plink --bfile ${merged_prefix}_qc \
        --extract ${merged_prefix}_qc.prune.in \
        --make-bed \
        --out ${merged_prefix}_qc_pruned"

# Run command with dx swiss-army-knife
dx run swiss-army-knife \
    -iin="${merged_dir}/${merged_prefix}.bed" \
    -iin="${merged_dir}/${merged_prefix}.bim" \
    -iin="${merged_dir}/${merged_prefix}.fam" \
    -iin="${pheno_dir}/${pheno_file}" \
    -icmd="${plink_cmd}" \
    --name "snp_qc" \
    --destination "${output_dir}/" \
    --yes \
    --wait

exit_code=$?
if [ $exit_code -ne 0 ]; then
    echo "Error: qc failed" > qc_results.txt
else
    echo ${output_dir} > qc_results.txt
    echo ${merged_prefix}_qc_pruned >> qc_results.txt
fi