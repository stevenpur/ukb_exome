

# apply SNP filter on each chromosome 1-22
source ~/ukb_rap/config.sh
for chr in {1..22}
do
    # set input file
    input_plink=${gt_dir}/ukb22418_c${chr}_b0_v2
    # plink commands for QC filter and LD pruning
    plink_cmd="plink --bfile $input_plink --mac 100 --maf 0.01 --hwe 1e-15 --mind 0.1 --geno 0.1 --indep-pairwise 1000 100 0.9 --out ${input_plink}_filtered"
    # run command with dx
    dx run swiss-army-knife \
        -iin="$input_plink" \
        -icmd="$plink_cmd" \
        --destination ${user_dir}/exom_test\
        --name snpQC_chr${chr} \
        --tag snpQC_chr${chr} \
        --yes \
        --watch
done

# set input files and make a merge list for plink
gt_dir="/Bulk/Genotype Results/Genotype calls"
input_cmd=()
for chr in {1..22}
do
    # set input files
    input_cmd+=("-iin=$gt_dir/ukb22418_c${chr}_b0_v2.bim")
    input_cmd+=("-iin=$gt_dir/ukb22418_c${chr}_b0_v2.fam")
    input_cmd+=("-iin=$gt_dir/ukb22418_c${chr}_b0_v2.bed")
done

# merge command
plink_cmd="ls *bed | sed 's/.bed//g' > merge_list.txt
    plink --merge-list merge_list.txt --make-bed --out ukb22418_merged_c1_22_v2_merged"
#echo $input_cmd

# run command
dx run swiss-army-knife "${input_cmd[@]}" \
    -icmd="$plink_cmd" \
    --destination /users/stevenpur/exom_test \
    --name gt_preprocess \
    --tag gt_preprocess \
    --yes \
    --watch \
    --priority normal

echo   "dx run swiss-army-knife "${input_cmd[@]}" \
    -icmd="$plink_cmd" \
    --destination /users/stevenpur/exom_test \
    --instance-type mem1_ssd1_gpu_x8 \
    --name gt_preprocess \
    --tag gt_preprocess \
    --yes \
    --watch \
    --priority normal"