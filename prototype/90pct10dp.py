#!/usr/bin/env python3
import argparse
import subprocess
import sys
import os

def main():
    parser = argparse.ArgumentParser(description='Filter 90pct10dp variants using PLINK')
    parser.add_argument('--exome_dir', required=True, help='Directory containing exome data')
    parser.add_argument('--exome_helper_dir', required=True, help='Directory containing helper files')
    parser.add_argument('--filter_90pct10dp_name', required=True, help='Name of the filter file')
    parser.add_argument('--output_dir', required=True, help='Output directory')
    parser.add_argument('--chr', required=True, help='Chromosome number')

    args = parser.parse_args()

    # Construct the PLINK command
    plink_cmd = f"plink --bfile ukb23158_c{args.chr}_b0_v1 " \
                f"--exclude {args.filter_90pct10dp_name} " \
                f"--make-bed " \
                f"--out ukb23158_c{args.chr}_b0_v1_filtered"

    # Construct the dx swiss-army-knife command
    dx_cmd = [
        "dx", "run", "swiss-army-knife",
        f"-iin={args.exome_dir}/ukb23158_c{args.chr}_b0_v1.bed",
        f"-iin={args.exome_dir}/ukb23158_c{args.chr}_b0_v1.bim",
        f"-iin={args.exome_dir}/ukb23158_c{args.chr}_b0_v1.fam",
        f"-iin={args.exome_helper_dir}/{args.filter_90pct10dp_name}",
        f"-icmd={plink_cmd}",
        "--name", f"90pct10dp_c{args.chr}",
        f"--destination", f"{args.output_dir}/",
        "--yes", "--wait"
    ]

    try:
        # Run the dx command
        result = subprocess.run(dx_cmd, check=True, capture_output=True, text=True)
        output_file = f"90pct10dp_results_c{args.chr}.txt"
        # Write success output
        with open(output_file, "w") as f:
            f.write(f"{args.output_dir}\n")
            f.write(f"ukb23158_c{args.chr}_b0_v1_filtered\n")
            
    except subprocess.CalledProcessError as e:
        # Write error output
        with open(output_file, "w") as f:
            f.write("Error: plink command failed\n")
        sys.exit(1)

if __name__ == "__main__":
    main() 