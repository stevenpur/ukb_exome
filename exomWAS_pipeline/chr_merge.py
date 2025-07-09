#!/usr/bin/env python3

import sys
import subprocess
import os
import argparse
import json

def main():
    # Parse arguments
    parser = argparse.ArgumentParser(description='Merge chromosome files using PLINK')
    parser.add_argument('--chrs', required=True, help='Comma-separated list of chromosomes')
    parser.add_argument('--gt_dir', required=True, help='Directory containing genotype files')
    parser.add_argument('--output_dir', required=True, help='Output directory')
    parser.add_argument('--dx_instance', required=True, help='DNAnexus instance type')
    
    args = parser.parse_args()
    
    # Get arguments
    chrs = args.chrs
    gt_dir = args.gt_dir
    output_dir = args.output_dir
    dx_instance = args.dx_instance
    prefix = "gt_merged_chr"  # Define prefix before using it
    # Split chromosomes into array
    chr_array = chrs.split(',')

    # Build input files for dx command
    in_files = []
    for chr_num in chr_array:
        in_prefix = gt_dir + "/ukb22418_c" + chr_num + "_b0_v2"
        for suffix in ["bed", "bim", "fam"]:
            in_files.extend([f"-iin={in_prefix}.{suffix}"])

    # Create PLINK merge command
    merge_cmd = f"""
    ls *_v2.bed | sed 's/.bed//g' > merge_list.txt
    plink --bfile ukb22418_c{chr_array[0]}_b0_v2 \
    --merge-list merge_list.txt \
    --make-bed \
    --out {prefix}
    """

    # Build dx command as a list
    dx_cmd = [
        "dx", "run", "swiss-army-knife",
        *in_files,
        f"-icmd={merge_cmd}",
        "--destination", f"{output_dir}/",
        "--instance-type", dx_instance,
        "--name", "gt_merge",
        "--wait",
        "--yes"
    ]

    # Execute the dx command with error handling
    try:
        result = subprocess.run(dx_cmd, check=True)
        # Write output in JSON format
        output_data = {
            "output_dir": output_dir,
            "prefix": prefix,
            "status": "success"
        }
        with open("merged_results.json", "w") as f:
            json.dump(output_data, f, indent=2)
    except subprocess.CalledProcessError as e:
        # Write error in JSON format
        error_data = {
            "status": "error",
            "error_type": "CalledProcessError",
            "exit_code": e.returncode,
            "message": f"Command failed with exit code {e.returncode}"
        }
        with open("merged_results.json", "w") as f:
            json.dump(error_data, f, indent=2)
        sys.exit(1)
    except Exception as e:
        # Write error in JSON format
        error_data = {
            "status": "error",
            "error_type": "Exception",
            "message": str(e)
        }
        with open("merged_results.json", "w") as f:
            json.dump(error_data, f, indent=2)
        sys.exit(1)

if __name__ == "__main__":
    main() 