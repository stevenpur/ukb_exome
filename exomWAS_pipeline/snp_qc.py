#!/usr/bin/env python3

import argparse
import subprocess
import os
import sys
import json

def parse_args():
    parser = argparse.ArgumentParser(description='Run SNP QC using PLINK')
    parser.add_argument('--merged_results', required=True, help='Path to merged results file')
    parser.add_argument('--pheno_desc', required=True, help='Path to phenotype description file')
    parser.add_argument('--output_dir', required=True, help='Output directory')
    return parser.parse_args()

def read_json_file(file_path):
    with open(file_path, 'r') as f:
        return json.load(f)

def main():
    args = parse_args()
    
    # Read merged results file
    merged_results = read_json_file(args.merged_results)
    if merged_results["status"] != "success":
        print(f"Error: Previous step failed: {merged_results.get('message', 'Unknown error')}")
        sys.exit(1)
    
    merged_dir = merged_results["output_dir"]
    merged_prefix = merged_results["prefix"]
    
    # Read phenotype results file
    pheno_results = read_json_file(args.pheno_desc)
    if pheno_results["status"] != "success":
        print(f"Error: Phenotype file error: {pheno_results.get('message', 'Unknown error')}")
        sys.exit(1)
    
    pheno_dir = pheno_results["pheno_dir"]
    pheno_file = pheno_results["pheno_file"]
    
    print(f"merged_prefix: {merged_prefix}")
    print(f"merged_dir: {merged_dir}")
    print(f"output_dir: {args.output_dir}")
    
    # Create PLINK commands
    plink_cmd = f"""
    # Get list of individuals to keep from phenotype file
    awk 'NR>1 {{print $1" "$2}}' {pheno_file} > keep.txt

    plink --bfile {merged_prefix} \
    --keep keep.txt \
    --mac 100 \
    --maf 0.01 \
    --mind 0.1 \
    --geno 0.1 \
    --hwe 1e-15 \
    --indep 50 5 2 \
    --make-bed \
    --out {merged_prefix}_qc

    plink --bfile {merged_prefix}_qc \
        --extract {merged_prefix}_qc.prune.in \
        --make-bed \
        --out {merged_prefix}_qc_pruned
    """
    
    # Run dx swiss-army-knife command
    dx_cmd = [
        'dx', 'run', 'swiss-army-knife',
        f'-iin={merged_dir}/{merged_prefix}.bed',
        f'-iin={merged_dir}/{merged_prefix}.bim',
        f'-iin={merged_dir}/{merged_prefix}.fam',
        f'-iin={pheno_dir}/{pheno_file}',
        f'-icmd={plink_cmd}',
        '--name', 'snp_qc',
        f'--destination', f'{args.output_dir}/',
        '--yes',
        '--wait'
    ]
    
    try:
        subprocess.run(dx_cmd, check=True)
        # Write success to qc_results.json
        output_data = {
            "output_dir": args.output_dir,
            "prefix": f"{merged_prefix}_qc_pruned",
            "status": "success"
        }
        with open('qc_results.json', 'w') as f:
            json.dump(output_data, f, indent=2)
    except subprocess.CalledProcessError as e:
        # Write error to qc_results.json
        error_data = {
            "status": "error",
            "error_type": "CalledProcessError",
            "exit_code": e.returncode,
            "message": "SNP QC failed"
        }
        with open('qc_results.json', 'w') as f:
            json.dump(error_data, f, indent=2)
        sys.exit(1)

if __name__ == '__main__':
    main() 