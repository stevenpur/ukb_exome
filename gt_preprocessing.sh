# set input files
for chr in {1..22}
do
    input_cmd=$input_cmd" -iin '/Bulk/Genotype\ Results/Genotype\ calls/ukb22418_c${chr}_b0_v2.bim' \
    -iin '/Bulk/Genotype\ Results/Genotype\ calls/ukb22418_c${chr}_b0_v2.fam' \
    -iin '/Bulk/Genotype\ Results/Genotype\ calls/ukb22418_c${chr}_b0_v2.bed' \"
done
echo $input_cmd
    