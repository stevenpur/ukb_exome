# run step 2 of regenie

source(../config.sh)
data_file_dir="${user_dir}/exom_test"
step1_pred_file="$user_dir/exom_test/test_result_pred.list"

# run for each chromosome 1-22 and X Y
for chr in {1..22} X Y
do
    run_regenie_cmd="regenie \
        --step 2 \
        --bed ukb23158_c${chr}_b0_v1 \
        --covarFile testing.covar \
        --phenoFile testing.phe \
        --extract wes_c${chr}_snps_qc_pass.snplist \
        --qt \
        --approx \
        --firth-se --firth \
        --pred test_result_chr${chr}.pred \
        --bsize 200 \
        --pThresh 0.05 \
        --minMAC 3 \
        --out test_result_chr${chr} \
        --threads 16 \
        --gz"

    dx run swiss-army-knife \
        -iin="${exom_plink_dir}/ukb23158_c${chr}_b0_v1.bed" \
        -iin="${exom_plink_dir}/ukb23158_c${chr}_b0_v1.bim" \
        -iin="${exom_plink_dir}/ukb23158_c${chr}_b0_v1.fam" \
        -iin="${data_file_dir}/testing.phe" \
        -iin="${data_file_dir}/testing.covar" \
        -iin="${data_file_dir}/wes_c${chr}_snps_qc_pass.snplist" \
        -iin="${step1_pred_file}" \
        -icmd="${run_regenie_cmd}" \
        --tag "regenie_step2" \
        --name "regenie_step2_chr${chr}" \
        --destination ${data_file_dir}/ \
        --instance-type mem1_ssd1_v2_x16 \
        --yes \
        --wait # to monitor without submitting too many jobs at once
done

