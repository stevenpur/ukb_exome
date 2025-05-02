#!/usr/bin/env python3

import sys
import subprocess
import os

def main():
    # Check if correct number of arguments is provided
    if len(sys.argv) != 5:
        print("Usage: python chr_merge.py <chromosomes> <genotype_dir> <output_dir> <dx_instance>")
        sys.exit(1)

    # Parse arguments
    chrs = sys.argv[1]
    gt_dir = sys.argv[2]
    output_dir = sys.argv[3]
    dx_instance = sys.argv[4]
    prefix = "gt_merged_chr_v2"  # Define prefix before using it

    # Split chromosomes into array
    chr_array = chrs.split(',')

    # Build input files string for dx command
    in_files = ""
    for chr_num in chr_array:
        in_prefix = gt_dir + "/ukb22418_c" + chr_num + "_b0_v2"
        for suffix in ["bed", "bim", "fam"]:
            in_files += " -iin=\"" + in_prefix + "." + suffix + "\""

    # Create PLINK merge command
    merge_cmd = f"""
    ls *_v2.bed | sed 's/.bed//g' > merge_list.txt
    plink --bfile ukb22418_c{chr_array[0]}_b0_v2 \
    --merge-list merge_list.txt \
    --make-bed \
    --out {prefix}
    """

    # Build and execute dx command
    dx_cmd = f"dx run swiss-army-knife {in_files} -icmd=\"{merge_cmd}\" --destination \"{output_dir}/\" --instance-type {dx_instance} --wait --yes"
    print(dx_cmd)

    # Execute the dx command and wait for completion, if failed, exit with error
    result = subprocess.run(dx_cmd, shell=True, check=True)
    if result.returncode != 0:
        print("Error: Command failed")
        sys.exit(1)

    # Print the output prefix and directory into a file
    with open("merged_results.txt", "w") as f:
        f.write(f"{output_dir}\n")
        f.write(f"{prefix}\n")

if __name__ == "__main__":
    main() 