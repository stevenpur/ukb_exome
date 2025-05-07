chr=$1
exome_dir=$2
output_dir=$3
dx_instance=$4

gt_dir="/Bulk/Genotype Results/Genotype calls"

echo "Parameters received:"
echo "chr: $chr"
echo "exome_dir: $exome_dir"
echo "output_dir: $output_dir"
echo "dx_instance: $dx_instance"

# Check if dx is available and authenticated
echo "Checking dx CLI..." >> hello2.txt
which dx >> hello2.txt
dx whoami >> hello2.txt

plink_cmd="plink --bfile ukb22418_c${chr}_b0_v2 --freq --out ukb22418_c${chr}_b0_v2_freq"
echo "Running dx command:" >> hello2.txt

dx run swiss-army-knife \
    -iin="${gt_dir}/ukb22418_c${chr}_b0_v2.bed" \
    -iin="${gt_dir}/ukb22418_c${chr}_b0_v2.bim" \
    -iin="${gt_dir}/ukb22418_c${chr}_b0_v2.fam" \
    -icmd="${plink_cmd}" \
    --destination "${output_dir}" \
    --wait
exit_code=$?
if [ $exit_code -ne 0 ]; then
    exit 1
fi
echo "dx command exit code: $exit_code" >> hello2.txt

echo 'hello world' >> hello2.txt