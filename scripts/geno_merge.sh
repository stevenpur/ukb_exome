# -------------------- 
# Notes: The script merge all chromosomes after the SNP QC and LD pruning.
# --------------------

source ../config.sh

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

plink_cmd+="ls *_v2.bed | sed 's/.bed//g' > merge_list.txt
    plink --merge-list merge_list.txt \
        --make-bed \
        --out ${output_file_merged}"

echo $plink_cmd

# run command
dx run swiss-army-knife "${input_cmd[@]}" \
    -icmd="$plink_cmd" \
    --destination "${user_dir}/" \
    --name gt_preprocess \
    --tag gt_preprocess \
    --yes \
    --watch \
    --priority normal \
    --instance-type mem1_ssd1_v2_x16 \
    --wait