#!/bin/bash

# Create merge list
for chr in {1..22}
do
    plink_cmd="plink --bfile ukb22418_c${chr}_b0_v2 \
        --extract ${rel_rsid} \
        --make-bed \
        --out ukb22418_c${chr}_rel"
        
    dx run swiss-army-knife \
        -iin=ukb22418_c${chr}_b0_v2.bed \
        -iin=ukb22418_c${chr}_b0_v2.bim \
        -iin=ukb22418_c${chr}_b0_v2.fam \
        -iin=${rel_rsid} \
        -icmd="$plink_cmd" \
        --destination . \
        --instance-type ${dx_instance} \
        --yes
done

ls *_rel.bed | sed 's/.bed//g' > merge_list.txt

merge_cmd="plink --merge-list merge_list.txt \
    --make-bed \
    --out ukb22418_merged_c1_22_v2_merged"
    
dx run swiss-army-knife \
    -iin=merge_list.txt \
    -iin=*_rel.bed \
    -iin=*_rel.bim \
    -iin=*_rel.fam \
    -icmd="$merge_cmd" \
    --destination . \
    --instance-type ${dx_instance} \
    --yes 