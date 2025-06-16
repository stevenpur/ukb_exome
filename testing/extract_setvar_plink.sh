exome_dir="/Bulk/Exome sequences/Population level exome OQFE variants, PLINK format - final release"

plink_cmd="
plink --bfile ukb23158_c1_b0_v1 \
--exclude ukb23158_500k_OQFE.90pct10dp_qc_variants.txt \
--extract ukb23158_500K_OQFE_chr1.sets.varid.txt \
--freq \
--out test_freq_chr1"

dx run swiss-army-knife \
-iin="${exome_dir}/ukb23158_c1_b0_v1.bed" \
-iin="${exome_dir}/ukb23158_c1_b0_v1.bim" \
-iin="${exome_dir}/ukb23158_c1_b0_v1.fam" \
-iin="${exome_dir}/helper_files/ukb23158_500k_OQFE.90pct10dp_qc_variants.txt" \
-iin="/users/steven/ukb23158_500K_OQFE_chr1.sets.varid.txt" \
-icmd="${plink_cmd}" \
--name test_freq_chr1 \
--instance-type mem1_ssd1_v2_x16 \
--destination /users/steven/ \
--yes \
--wait

