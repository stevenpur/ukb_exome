# run regenie step 1 on ukb_rap
data_file_dir="/users/stevenpur/exom_test"
out_prefix="test_result"
pheno_prefix="testing"
merged_plink_file="ukb22418_merged_c1_22_v2_merged_qc_pruned"
pheno_name="overall_activity"

run_regeni_step1="regenie --step 1 \
    --lowmem --out ${out_prefix} \
    --bed $merged_plink_file \
    --phenoFile ${pheno_prefix}.phe \
    --covarFile ${pheno_prefix}.covar \
    --phenoCol $pheno_name \
    --bsize 1000 --qt --loocv --gz --threads 16"

dx run swiss-army-knife \
    -iin=${data_file_dir}/${merged_plink_file}.bed \
    -iin=${data_file_dir}/${merged_plink_file}.bim \
    -iin=${data_file_dir}/${merged_plink_file}.fam \
    -iin=${data_file_dir}/${pheno_prefix}.phe \
    -iin=${data_file_dir}/${pheno_prefix}.covar \
    -icmd="${run_regeni_step1}" \
    --tag "regenie_step1" \
    --destination ${data_file_dir}/ \
    --instance-type mem1_ssd1_v2_x36 \
    --yes \
