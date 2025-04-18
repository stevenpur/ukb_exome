# --------------------
# Notes: The script merge all chromosomes after the SNP QC and LD pruning.
# --------------------

source ~/ukb_rap/config.sh

# set input files and make a merge list for plink
input_cmd=()
for chr in {1..22}
do
    # set input files
    input_cmd+=("-iin=$gt_dir/ukb22418_c${chr}_b0_v2.bim")
    input_cmd+=("-iin=$gt_dir/ukb22418_c${chr}_b0_v2.fam")
    input_cmd+=("-iin=$gt_dir/ukb22418_c${chr}_b0_v2.bed")
done
output_file_merged="ukb22418_merged_c1_22_v2_merged"
output_file_qc="ukb22418_merged_c1_22_v2_merged_qc"
output_file_pruned="ukb22418_merged_c1_22_v2_merged_qc_pruned"

# command to merge, QC, and prune
plink_cmd=""
for chr in {1..22}
do
    # concat the plink command
    plink_cmd+="plink --bfile ukb22418_c${chr}_b0_v2 \
        --extract rel_rsid.txt \
        --make-bed \
        --out ukb22418_c${chr}_rel
    "
done
plink_cmd+="ls *_rel.bed | sed 's/.bed//g' > merge_list.txt
    plink --merge-list merge_list.txt \
        --make-bed \
        --out ${output_file_merged}
    plink --bfile ${output_file_merged} \
        --mac 100 \
        --maf 0.01 \
        --hwe 1e-15 \
        --mind 0.1 \
        --geno 0.1 \
        --make-bed \
        --out ${output_file_qc}"

echo $plink_cmd

# run command
dx run swiss-army-knife "${input_cmd[@]}" \
    -iin="${user_dir}/exom_test/rel_rsid.txt" \
    -icmd="$plink_cmd" \
    --destination "${user_dir}/exom_test" \
    --name gt_preprocess \
    --tag gt_preprocess \
    --yes \
    --watch \
    --priority normal \
    --instance-type mem1_ssd1_v2_x16 \
    --wait

# clean the intermediate files
#dx rm "${user_dir}/exom_test/ukb22418_merged_c1_22_v2_merged.bed"
#dx rm "${user_dir}/exom_test/ukb22418_merged_c1_22_v2_merged.bim"
#dx rm "${user_dir}/exom_test/ukb22418_merged_c1_22_v2_merged.fam"
#dx rm "${user_dir}/exom_test/ukb22418_merged_c1_22_v2_merged_qc.bed"
#dx rm "${user_dir}/exom_test/ukb22418_merged_c1_22_v2_merged_qc.bim"
#dx rm "${user_dir}/exom_test/ukb22418_merged_c1_22_v2_merged_qc.fam"