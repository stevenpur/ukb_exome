while [[ $# -gt 0 ]]; do
    case $1 in
        --regenie_step1_results)
            regenie_step1_results_file="$2"
            shift 2
            ;;
        --exome_qc_results) 
            exom_qc_results_file="$2"
            shift 2
            ;;
        --exome_helper_dir)
            exome_helper_dir="$2"
            shift 2
            ;;
        --pheno_desc)
            pheno_desc_file="$2"
            shift 2
            ;;
        --out_dir)
            output_dir="$2"
            shift 2
            ;;
        --chr)
            chr="$2"
            shift 2
            ;;
        *)
            echo "Unknown parameter: $1"
            exit 1
            ;;
    esac
done

regenie_step1_dir=$(head -n 1 ${regenie_step1_results_file})
regenie_step1_prefix=$(tail -n 1 ${regenie_step1_results_file})
exome_dir=$(head -n 1 ${exom_qc_results_file})
exome_prefix=$(tail -n 1 ${exom_qc_results_file})
pheno_dir=$(head -n 1 ${pheno_desc_file})
pheno_file=$(tail -n 2 ${pheno_desc_file} | head -n 1)
covar_file=$(tail -n 1 ${pheno_desc_file})

echo "exome_dir: ${exome_dir}"
echo "exome_prefix: ${exome_prefix}"
echo "pheno_dir: ${pheno_dir}"
echo "pheno_file: ${pheno_file}"
echo "covar_file: ${covar_file}"

regenie_step2_cmd="
    regenie \
    --step 2 \
    --bed ${exome_prefix} \
    --ref-first \
    --phenoFile ${pheno_file} \
    --covarFile ${covar_file} \
    --set-list ukb23158_500k_OQFE.sets.txt.gz \
    --anno-file ukb23158_500k_OQFE.annotations.txt.gz \
    --mask-def ukb23158_500k_OQFE.masks \
    --extract ukb23158_500k_OQFE.90pct10dp_qc_variants.txt \
    --pred ${regenie_step1_prefix}_regenie_step1_pred.list \
    --nauto 2 \
    --aaf-bins 0.01,0.001 \
    --bsize 200 \
    --out ${regenie_step1_prefix}_regenie_step2"

# Run command with dx swiss-army-knife
dx run swiss-army-knife \
    -iin="${exome_dir}/${exome_prefix}.bed" \
    -iin="${exome_dir}/${exome_prefix}.bim" \
    -iin="${exome_dir}/${exome_prefix}.fam" \
    -iin="${regenie_step1_dir}/${regenie_step1_prefix}_regenie_step1_pred.list" \
    -iin="${exome_helper_dir}/ukb23158_500k_OQFE.sets.txt.gz" \
    -iin="${exome_helper_dir}/ukb23158_500k_OQFE.annotations.txt.gz" \
    -iin="${exome_helper_dir}/ukb23158_500k_OQFE.90pct10dp_qc_variants.txt" \
    -iin="${exome_helper_dir}/ukb23158_500k_OQFE.masks" \
    -iin="${regenie_step1_dir}/${regenie_step1_prefix}_regenie_step1_pred.list" \
    -iin="${pheno_dir}/${pheno_file}" \
    -iin="${pheno_dir}/${covar_file}" \
    -icmd="${regenie_step2_cmd}" \
    --destination "${output_dir}/" \
    --instance-type "mem1_ssd1_v2_x8" \
    --priority high \
    --destination "${output_dir}/" --yes --wait

exit_code=$?
if [ $exit_code -ne 0 ]; then
    echo "Error: regenie step 2 failed" > regenie_step2_results.txt
else
    echo ${output_dir} > regenie_step2_results.txt
    echo ${regenie_step1_prefix}_regenie_step2 >> regenie_step2_results.txt
fi
