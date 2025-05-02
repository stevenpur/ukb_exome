gt_input_files=$1
pheno_results_file=$2
output_dir=$3

gt_dir=$(head -n 1 ${gt_input_files})
gt_prefix=$(tail -n 1 ${gt_input_files})
pheno_dir=$(head -n 1 ${pheno_results_file})
pheno_file=$(tail -n 2 ${pheno_results_file} | head -n 1)
covar_file=$(tail -n 1 ${pheno_results_file})

echo "gt_dir: ${gt_dir}"
echo "gt_prefix: ${gt_prefix}"
echo "pheno_dir: ${pheno_dir}"
echo "pheno_file: ${pheno_file}"
echo "covar_file: ${covar_file}"

regenie_step1_cmd="
    regenie \
    --step 1 \
    --bed ${gt_prefix} \
    --phenoFile ${pheno_file} \
    --covarFile ${covar_file} \
    --bsize 1000 \
    --out ${gt_prefix}_regenie_step1 \
    --lowmem"

# Run command with dx swiss-army-knife
dx run swiss-army-knife \
    -iin="${gt_dir}/${gt_prefix}.bed" \
    -iin="${gt_dir}/${gt_prefix}.bim" \
    -iin="${gt_dir}/${gt_prefix}.fam" \
    -iin="${pheno_dir}/${pheno_file}" \
    -iin="${pheno_dir}/${covar_file}" \
    -icmd="${regenie_step1_cmd}" \
    --instance-type "mem1_ssd1_v2_x8" \
    --priority high \
    --destination "${output_dir}/" --yes --wait

exit_code=$?
if [ $exit_code -ne 0 ]; then
    echo "Error: regenie step 1 failed" > regenie_step1_results.txt
else
    echo ${output_dir} > regenie_step1_results.txt
    echo ${gt_prefix}_regenie_step1 >> regenie_step1_results.txt
fi

