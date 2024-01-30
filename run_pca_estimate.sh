# run pc estimation on ukb_rap
source ../config.sh
run_pca_estimate="Rscript pc_estimate.r"

dx run swiss-army-knife \
    -iin=${user_dir}/pc_estimate.r \
    -icmd="${run_pca_estimate}" \
    --destination ${user_dir}/exom_test \
    --instance-type mem1_ssd1_v2_x36 \
    --tag "pc_estimate" \
    --yes
