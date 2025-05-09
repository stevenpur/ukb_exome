#!/usr/bin/env python3

import argparse
import subprocess
import sys
from pathlib import Path

def parse_args():
    parser = argparse.ArgumentParser(description='Run REGENIE step 1 analysis')
    parser.add_argument('--gt_input_files', required=True, help='File containing genotype input paths')
    parser.add_argument('--pheno_desc', required=True, help='File containing phenotype description paths')
    parser.add_argument('--output_dir', required=True, help='Output directory')
    return parser.parse_args()

def read_first_line(file_path):
    with open(file_path, 'r') as f:
        return f.readline().strip()

def read_last_line(file_path):
    with open(file_path, 'r') as f:
        lines = f.readlines()
        return lines[-1].strip()

def read_second_last_line(file_path):
    with open(file_path, 'r') as f:
        lines = f.readlines()
        return lines[-2].strip()

def main():
    args = parse_args()
    
    # Read input files
    gt_dir = read_first_line(args.gt_input_files)
    gt_prefix = read_last_line(args.gt_input_files)
    pheno_dir = read_first_line(args.pheno_desc)
    pheno_file = read_second_last_line(args.pheno_desc)
    covar_file = read_last_line(args.pheno_desc)

    # Print input information
    print(f"gt_dir: {gt_dir}")
    print(f"gt_prefix: {gt_prefix}")
    print(f"pheno_dir: {pheno_dir}")
    print(f"pheno_file: {pheno_file}")
    print(f"covar_file: {covar_file}")

    # Construct regenie command
    regenie_step1_cmd = f"""
    regenie \
    --step 1 \
    --bed {gt_prefix} \
    --phenoFile {pheno_file} \
    --covarFile {covar_file} \
    --bsize 1000 \
    --out {gt_prefix}_regenie_step1 \
    --lowmem
    """

    # Construct dx command
    dx_cmd = [
        "dx", "run", "swiss-army-knife",
        f"-iin={gt_dir}/{gt_prefix}.bed",
        f"-iin={gt_dir}/{gt_prefix}.bim",
        f"-iin={gt_dir}/{gt_prefix}.fam",
        f"-iin={pheno_dir}/{pheno_file}",
        f"-iin={pheno_dir}/{covar_file}",
        f"-icmd={regenie_step1_cmd}",
        "--name", "regenie_step1",
        "--instance-type", "mem1_ssd1_v2_x8",
        "--priority", "high",
        "--destination", f"{args.output_dir}/",
        "--yes", "--wait"
    ]

    # Run the command
    try:
        subprocess.run(dx_cmd, check=True)
        # Write success to results file
        with open("regenie_step1_results.txt", "w") as f:
            f.write(f"{args.output_dir}\n")
            f.write(f"{gt_prefix}_regenie_step1\n")
    except subprocess.CalledProcessError:
        # Write error to results file
        with open("regenie_step1_results.txt", "w") as f:
            f.write("Error: regenie step 1 failed\n")
        sys.exit(1)

if __name__ == "__main__":
    main() 