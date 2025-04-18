# Run QC on exome seuqencing data
source ../config.sh
exom_plink_dir="/Bulk/Exome sequences/Population level exome OQFE variants, PLINK format - final release"
data_file_dir="${user_dir}/exom_test"

# QC on autosomes
for chr in {1..22}; do
    run_plink_wes="plink2 \
        --bfile ukb23158_c${chr}_b0_v1 \
        --no-pheno \
        --keep testing.phe \
        --autosome \
        --mac 20 --geno 0.1 --hwe 1e-15 --mind 0.1 \
        --write-snplist --write-samples --no-id-header \
        --out wes_c${chr}_snps_qc_pass"
    
    dx run swiss-army-knife \
        -iin="${exom_plink_dir}/ukb23158_c${chr}_b0_v1.bed" \
        -iin="${exom_plink_dir}/ukb23158_c${chr}_b0_v1.bim" \
        -iin="${exom_plink_dir}/ukb23158_c${chr}_b0_v1.fam" \
        -iin="${data_file_dir}/testing.phe" \
        -icmd="${run_plink_wes}" \
        --tag "wes_qc" \
        --name "wes_qc_chr${chr}" \
        --destination ${data_file_dir}/ \
        --instance-type mem1_ssd1_v2_x16 \
        --brief \
        --yes 
done
