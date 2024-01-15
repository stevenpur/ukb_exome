# --------------------
# Notes: This script is meant to produce the genotype data needed for step 1 of REGENIE.
#        The script merge all chromosomes after the SNP QC and LD pruning. This is all done in DNA Nexus platform.
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
plink_cmd="ls *bed | sed 's/.bed//g' > merge_list.txt
    plink --merge-list merge_list.txt \
        --make-bed \
        --out ${output_file_merged}
    plink --bfile ${output_file_merged} \
        --mac 100 \
        --maf 0.01 \
        --hwe 1e-15 \
        --mind 0.1 \
        --geno 0.1 \
        --indep-pairwise 1000 100 0.9 \
        --make-bed \
        --out ${output_file_qc}
    plink --bfile ${output_file_qc} \
        --extract ${output_file_qc}.prune.in \
        --make-bed \
        --out ${output_file_pruned}"

echo $plink_cmd

# run command
dx run swiss-army-knife "${input_cmd[@]}" \
    -icmd="$plink_cmd" \
    --destination "${user_dir}/exom_test" \
    --name gt_preprocess \
    --tag gt_preprocess \
    --yes \
    --watch \
    --priority normal \
    --wait

# clean the intermediate files
dx rm "${user_dir}/exom_test/ukb22418_merged_c1_22_v2_merged.bed"
dx rm "${user_dir}/exom_test/ukb22418_merged_c1_22_v2_merged.bim"
dx rm "${user_dir}/exom_test/ukb22418_merged_c1_22_v2_merged.fam"
dx rm "${user_dir}/exom_test/ukb22418_merged_c1_22_v2_merged_qc.bed"
dx rm "${user_dir}/exom_test/ukb22418_merged_c1_22_v2_merged_qc.bim"
dx rm "${user_dir}/exom_test/ukb22418_merged_c1_22_v2_merged_qc.fam"