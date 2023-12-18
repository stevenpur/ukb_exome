# Purpose: Perform SNP QC on each chromosome and merge all chromosomes
source ../config.sh
# Enter working directory
echo "Enter working directory \"${user_dir}\"/exom_test"
dx cd "${user_dir}"/exom_test

# apply SNP filter on each chromosome 1-22
for chr in {1..22}
do
    # set input file
    input_plink="${gt_dir}/ukb22418_c${chr}_b0_v2"
    # plink commands for QC filter and LD pruning
    plink_cmd="plink --bfile ukb22418_c${chr}_b0_v2 \
        --mac 100 \
        --maf 0.01 \
        --hwe 1e-15 \
        --mind 0.1 \
        --geno 0.1 \
        --indep-pairwise 1000 100 0.9 \
        --make-bed \
        --out ukb22418_c${chr}_b0_v2_qc
        plink --bfile ukb22418_c${chr}_b0_v2_qc \
        --extract ukb22418_c${chr}_b0_v2_qc.prune.in \
        --make-bed \
        --out ukb22418_c${chr}_b0_v2_qc_pruned"
    # run command with dx
    echo "run command with dx on chromosome ${chr}"
    echo plink_cmd
    dx run swiss-army-knife \
        -iin="$input_plink".bim \
        -iin="$input_plink".fam \
        -iin="$input_plink".bed \
        -icmd="$plink_cmd" \
        --destination "${user_dir}/exom_test"\
        --name snpQC_chr${chr} \
        --tag snpQC_chr${chr} \
        --yes \
        --watch
done

# merge all chromosomes after the SNP QC
input_cmd=()
for chr in {1..22}
do
    # set input files
    input_plink="${user_dir}/exom_test/ukb22418_c${chr}_b0_v2_qc_pruned"
    input_cmd+=("-iin=$input_plink.bim")
    input_cmd+=("-iin=$input_plink.fam")
    input_cmd+=("-iin=$input_plink.bed")
done

# merge command
plink_cmd="ls *bed | sed 's/.bed//g' > merge_list.txt
    plink --merge-list merge_list.txt \
    --make-bed \
    --out ukb22418_merged_c1_22_v2_merged"

# run merge command
dx run swiss-army-knife "${input_cmd[@]}" \
    -icmd="$plink_cmd" \
    --destination /users/stevenpur/exom_test \
    --name gt_merge \
    --tag gt_merge \
    --yes \
    --watch \

# remove the filtered snps to save space
#dx rm "${user_dir}/exom_teset/ukb22418_c${chr}_b0_v2_filtered*"