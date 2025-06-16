#!/usr/bin/env python3
import argparse
import subprocess
import sys
import os

def parse_args():
    parser = argparse.ArgumentParser(description='Run REGENIE step 2 analysis')
    parser.add_argument('--regenie_step1_results', required=True, help='Path to regenie step1 results file')
    parser.add_argument('--exome_dir', required=True, help='Path to exome directory')
    parser.add_argument('--exome_helper_dir', required=True, help='Path to exome helper directory')
    parser.add_argument('--pheno_desc', required=True, help='Path to phenotype description file')
    parser.add_argument('--out_dir', required=True, help='Output directory')
    parser.add_argument('--chr', required=True, help='Chromosome number')
    return parser.parse_args()

def read_first_line(file_path):
    with open(file_path, 'r') as f:
        return f.readline().strip()

def read_last_line(file_path):
    with open(file_path, 'r') as f:
        return f.readlines()[-1].strip()

def read_second_to_last_line(file_path):
    with open(file_path, 'r') as f:
        lines = f.readlines()
        return lines[-2].strip()

def main():
    args = parse_args()

    # Read input files
    regenie_step1_dir = read_first_line(args.regenie_step1_results)
    regenie_step1_prefix = read_last_line(args.regenie_step1_results)
    exome_dir = args.exome_dir
    pheno_dir = read_first_line(args.pheno_desc)
    pheno_file = read_second_to_last_line(args.pheno_desc)
    covar_file = read_last_line(args.pheno_desc)

    # Print input information
    print(f"regenie step 1 directory: {regenie_step1_dir}")
    print(f"regenie step 1 prefix: {regenie_step1_prefix}")
    print(f"exome directory: {exome_dir}")
    print(f"pheno directory: {pheno_dir}")
    print(f"pheno file: {pheno_file}")
    print(f"covar file: {covar_file}")

    # filter the sets file to only include the chromosome
    filter_cmd = f"""
    zgrep -P "^[^\t]+\t{args.chr}\t" ukb23158_500k_OQFE.sets.txt.gz | bgzip -c > ukb23158_500k_OQFE_chr{args.chr}.sets.txt.gz
    """

    # Construct regenie command
    regenie_step2_cmd = f"""
    regenie \
    --step 2 \
    --bed ukb23158_c{args.chr}_b0_v1 \
    --phenoFile {pheno_file} \
    --covarFile {covar_file} \
    --pred {regenie_step1_prefix}_pred.list \
    --chr {args.chr} \
    --aaf-bins 0.01,0.001 \
    --set-list ukb23158_500k_OQFE_chr{args.chr}.sets.txt.gz \
    --anno-file ukb23158_500k_OQFE.annotations.txt.gz \
    --mask-def ukb23158_500k_OQFE.masks \
    --exclude ukb23158_500k_OQFE.90pct10dp_qc_variants.txt \
    --nauto 23 \
    --bsize 200 \
    --out {regenie_step1_prefix}_c{args.chr}_step2 \
    --check-burden-files \
    --write-mask-snplist
    """

    # Combine filter and regenie commands
    combined_cmd = f"{filter_cmd.strip()} && {regenie_step2_cmd.strip()}"

    # get the step1 .loco files
    cmd = f"dx ls {regenie_step1_dir}/{regenie_step1_prefix}*.loco"
    loco_files = subprocess.check_output(cmd, shell=True).decode('utf-8').strip().split('\n')
    loco_files = [f"-iin={regenie_step1_dir}/{file}" for file in loco_files]

    # Construct dx command
    dx_cmd = [
        'dx', 'run', 'swiss-army-knife',
        f'-iin={exome_dir}/ukb23158_c{args.chr}_b0_v1.bed',
        f'-iin={exome_dir}/ukb23158_c{args.chr}_b0_v1.bim',
        f'-iin={exome_dir}/ukb23158_c{args.chr}_b0_v1.fam',
        f'-iin={regenie_step1_dir}/{regenie_step1_prefix}_pred.list',
        *loco_files,
        f'-iin={args.exome_helper_dir}/ukb23158_500k_OQFE.sets.txt.gz',
        f'-iin={args.exome_helper_dir}/ukb23158_500k_OQFE.annotations.txt.gz',
        f'-iin={args.exome_helper_dir}/ukb23158_500k_OQFE.90pct10dp_qc_variants.txt',
        f'-iin={args.exome_helper_dir}/ukb23158_500k_OQFE.masks',
        f'-iin={pheno_dir}/{pheno_file}',
        f'-iin={pheno_dir}/{covar_file}',
        f'-icmd={combined_cmd}',
        '--name', f'regenie_step2_c{args.chr}',
        f'--destination={args.out_dir}/',
        '--instance-type', 'mem1_ssd1_v2_x16',
        '--priority', 'high',
        '--yes',
        '--wait'
    ]

    # Run dx command
    output_file = f"regenie_step2_results_c{args.chr}.txt"
    try:
        subprocess.run(dx_cmd, check=True)
        # Write success output
        with open(output_file, 'w') as f:
            f.write(f"{args.out_dir}\n")
            f.write(f"{regenie_step1_prefix}_c{args.chr}_step2\n")
    except subprocess.CalledProcessError:
        # Write error output
        with open(output_file, 'w') as f:
            f.write("Error: regenie step 2 failed\n")
        sys.exit(1)

if __name__ == "__main__":
    main() 