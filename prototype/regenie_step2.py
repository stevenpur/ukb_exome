#!/usr/bin/env python3

import subprocess
import sys
import os

def main():
    if len(sys.argv) != 7:
        print("Usage: python regenie_step2.py <regenie_step1_results_file> <exome_dir> <exom_helper_dir> <pheno_results_file> <output_dir> <chr>")
        sys.exit(1)

    # Parse command line arguments
    regenie_step1_results_file = sys.argv[1]
    exome_dir = sys.argv[2]
    exom_helper_dir = sys.argv[3]
    pheno_results_file = sys.argv[4]
    output_dir = sys.argv[5]
    chr = sys.argv[6]

    # Read input files
    with open(regenie_step1_results_file, 'r') as f:
        regenie_step1_dir = f.readline().strip()
        regenie_step1_prefix = f.readline().strip()

    with open(pheno_results_file, 'r') as f:
        pheno_dir = f.readline().strip()
        pheno_file = f.readline().strip()
        covar_file = f.readline().strip()

    # Print input information
    print(f"gt_dir: {exome_dir}")
    print(f"gt_prefix: ukb23158_c{chr}_b0_v1")
    print(f"pheno_dir: {pheno_dir}")
    print(f"pheno_file: {pheno_file}")

    # Construct subset command
    subset_cmd = f"zgrep -P '^[^\t]+\t{chr}\t' ukb23158_500k_OQFE.sets.txt.gz | bgzip -c > ukb23158_500k_OQFE_chr{chr}.sets.gz"
    
    # Construct regenie command
    regenie_step2_cmd = [
        "regenie",
        "--step", "2",
        "--bed", f"ukb23158_c{chr}_b0_v1",
        "--ref-first",
        "--phenoFile", pheno_file,
        "--covarFile", covar_file,
        "--set-list", f"ukb23158_500k_OQFE_chr{chr}.sets.gz",
        "--anno-file", "ukb23158_500k_OQFE.annotations.txt.gz",
        "--mask-def", "ukb23158_500k_OQFE.masks",
        "--extract", "ukb23158_500k_OQFE.90pct10dp_qc_variants.txt",
        "--pred", f"{regenie_step1_prefix}_pred.list",
        "--nauto", "22",
        "--aaf-bins", "0.01,0.001",
        "--bsize", "200",
        "--out", f"{regenie_step1_prefix}_regenie_step2"
    ]

    # Combine commands into a single shell command
    full_cmd = f"{subset_cmd} && {' '.join(regenie_step2_cmd)}"

    # Construct dx command
    dx_cmd = [
        "dx", "run", "swiss-army-knife",
        f"-iin={exome_dir}/ukb23158_c{chr}_b0_v1.bed",
        f"-iin={exome_dir}/ukb23158_c{chr}_b0_v1.bim",
        f"-iin={exome_dir}/ukb23158_c{chr}_b0_v1.fam",
        f"-iin={regenie_step1_dir}/{regenie_step1_prefix}_pred.list",
        f"-iin={regenie_step1_dir}/{regenie_step1_prefix}_1.loco",
        f"-iin={exom_helper_dir}/ukb23158_500k_OQFE.sets.txt.gz",
        f"-iin={exom_helper_dir}/ukb23158_500k_OQFE.annotations.txt.gz",
        f"-iin={exom_helper_dir}/ukb23158_500k_OQFE.90pct10dp_qc_variants.txt",
        f"-iin={exom_helper_dir}/ukb23158_500k_OQFE.masks",
        f"-iin={pheno_dir}/{pheno_file}",
        f"-iin={pheno_dir}/{covar_file}",
        f"-icmd={full_cmd}",
        f"--destination", f"{output_dir}/",
        "--instance-type", "mem1_ssd1_v2_x8",
        "--priority", "high",
        "--destination", f"{output_dir}/",
        "--yes",
        "--wait"
    ]

    # Run dx command
    try:
        subprocess.run(dx_cmd, check=True)
        # Write success output
        with open("regenie_step2_results.txt", "w") as f:
            f.write(f"{output_dir}\n")
            f.write(f"{regenie_step1_prefix}_regenie_step2\n")
    except subprocess.CalledProcessError:
        # Write error output
        with open("regenie_step2_results.txt", "w") as f:
            f.write("Error: regenie step 2 failed\n")
        sys.exit(1)

if __name__ == "__main__":
    main() 