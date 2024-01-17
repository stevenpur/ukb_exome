# Run QC on exome seuqencing data

exom_file_dir="/Bulk/Exome sequences/Population level exome OQFE variants, PLINK format - final release"
data_file_dir="/users/stevenpur/exom_test"

# QC on autosomes
for chr in {1..22}; do
    run_plink_wes="plink2 \
        --bfile ukb23158_c${chr}_b0_v1 \
        --no-pheno \
        --keep ${data_file_dir}/testing.phe \
        --autosome \
        --mac 20 --geno 0.1 --hwe 1e-15 --mind 0.1 \
        --write-snplist --write-samples --no-id-header \
        --out wes_c${chr}_snps_qc_pass"
    
    dx run swiss-army-knife \
        -iin="${exom_file_dir}/ukb23158_c${chr}_b0_v1.bed" \
        -iin="${exom_file_dir}/ukb23158_c${chr}_b0_v1.bim" \
        -iin="${exom_file_dir}/ukb23158_c${chr}_b0_v1.fam" \
        -icmd="${run_plink_wes}" \
        --tag "wes_qc" \
        --name "wes_qc_chr${chr}" \
        --destination ${data_file_dir}/ \
        --instance-type mem1_ssd1_v2_x16 \
        --brief \
        --yes \

done

# QC on X and Y chromosomes
for chr in X Y
do
    run_plink_wes="plink2 \
        --bfile ukb23158_c${chr}_b0_v1 \
        --no-pheno \
        --keep ${data_file_dir}/testing.phe \
        --autosome \
        --mac 20 --geno 0.1 --hwe 1e-15 --mind 0.1 \
        --write-snplist --write-samples --no-id-header \
        --out wes_c${chr}_snps_qc_pass"
    
    dx run swiss-army-knife \
        -iin="${exom_file_dir}/ukb23158_c${chr}_b0_v1.bed" \
        -iin="${exom_file_dir}/ukb23158_c${chr}_b0_v1.bim" \
        -iin="${exom_file_dir}/ukb23158_c${chr}_b0_v1.fam" \
        -icmd="${run_plink_wes}" \
        --tag "wes_qc" \
        --name "wes_qc_chr${chr}"
        --destination=${data_file_dir}/ \
        --instance-type mem1_ssd1_v2_x16 \
        --brief \
        --yes \
done

