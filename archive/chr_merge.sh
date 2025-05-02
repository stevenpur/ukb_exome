 # Create a list of files to merge for all chromosomes
chrs=$1
gt_dir=$2
output_dir=$3
dx_instance=$4

# split chrs into an array by comma
chr_array=(${chrs//,/ })
echo ${chr_array[0]} >> merge_list.txt
echo ${chr_array[1]} >> merge_list.txt

prefix="gt_merged_chr_v2"
in_files=""
for chr in ${chr_array[@]}; do
    in_prefix="${gt_dir}/ukb22418_c${chr}_b0_v2"
    in_files="${in_files} -iin=\"${in_prefix}.bed\" -iin=\"${in_prefix}.bim\" -iin=\"${in_prefix}.fam\""
done

merge_cmd="
    ls *_v2.bed | sed 's/.bed//g' > merge_list.txt
    plink --bfile ukb22418_c${chr_array[0]}_b0_v2 \
    --merge-list merge_list.txt \
    --make-bed \
    --out ${prefix}"

# Run command with dx swiss-army-knife
dx run swiss-army-knife "${in_files}" \
    -icmd="${merge_cmd}" \
    --destination "${output_dir}/" \
    --instance-type ${dx_instance} \
    --yes \
    --wait 

exit_code=$?
if [ $exit_code -ne 0 ]; then
    exit 1
else
    echo ${output_dir} > merged_results.txt
    echo ${prefix} >> merged_results.txt
fi