#!/usr/bin/env python3

import argparse
import subprocess
import sys
import json
from pathlib import Path

def parse_args():
    parser = argparse.ArgumentParser(description='Run REGENIE step 1 analysis')
    parser.add_argument('--gt_input_files', required=True, help='File containing genotype input paths')
    parser.add_argument('--pheno_desc', required=True, help='File containing phenotype description paths')
    parser.add_argument('--output_dir', required=True, help='Output directory')
    return parser.parse_args()

def read_json_file(file_path):
    with open(file_path, 'r') as f:
        return json.load(f)

def main():
    args = parse_args()
    
    # Read input files
    gt_data = read_json_file(args.gt_input_files)
    if gt_data["status"] != "success":
        print(f"Error: Genotype input error: {gt_data.get('message', 'Unknown error')}")
        sys.exit(1)
    
    gt_dir = gt_data["output_dir"]
    gt_prefix = gt_data["prefix"]
    
    pheno_data = read_json_file(args.pheno_desc)
    if pheno_data["status"] != "success":
        print(f"Error: Phenotype file error: {pheno_data.get('message', 'Unknown error')}")
        sys.exit(1)
    
    pheno_dir = pheno_data["pheno_dir"]
    pheno_file = pheno_data["pheno_file"]
    covar_file = pheno_data["covar_file"]

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
        output_data = {
            "output_dir": args.output_dir,
            "prefix": f"{gt_prefix}_regenie_step1",
            "status": "success"
        }
        with open("regenie_step1_results.json", "w") as f:
            json.dump(output_data, f, indent=2)
    except subprocess.CalledProcessError as e:
        # Write error to results file
        error_data = {
            "status": "error",
            "error_type": "CalledProcessError",
            "exit_code": e.returncode,
            "message": "REGENIE step 1 failed"
        }
        with open("regenie_step1_results.json", "w") as f:
            json.dump(error_data, f, indent=2)
        sys.exit(1)

if __name__ == "__main__":
    main() 