# pool results from multiple chromosomes for each phenotype
import argparse
import os
import subprocess
import sys

def parse_args():
    parser = argparse.ArgumentParser(description='Pool results from multiple chromosomes')
    parser.add_argument('--regenie_step2_results', required=True, help='Path to regenie step2 results file')
    parser.add_argument('--output_dir', required=True, help='Output directory')
    parser.add_argument('--pheno', required=True, help='Phenotype names, separated by comma')
    return parser.parse_args()

def read_first_line(file_path):
    with open(file_path, 'r') as f:
        return f.readline().strip()

def read_last_line(file_path):
    with open(file_path, 'r') as f:
        lines = f.readlines()
        return lines[-1].strip()

def get_chr_num(filename):
            # Extract chromosome number from filename that contains '_c{chr}_step2_'
            chr_part = filename.split('_step2_')[0]  # get everything before _step2_
            chr_num = chr_part.split('_c')[-1]  # get the number after last _c
            if chr_num == 'X':
                return 23
            elif chr_num == 'Y':
                return 24
            elif chr_num == 'MT':
                return 25
            else:
                return int(chr_num)

def main():
    args = parse_args()
    regenie_step2_dir = read_first_line(args.regenie_step2_results)
    regenie_step2_prefix = '_'.join(read_last_line(args.regenie_step2_results).split('_')[:-2])
    output_dir = args.output_dir

    print(f"regenie step2 directory: {regenie_step2_dir}")
    print(f"regenie step2 prefix: {regenie_step2_prefix}")
    print(f"output directory: {output_dir}")

    # read all files in regenie_step2_dir
    for pheno in args.pheno.split(','):
        fs_cmd = f"dx ls {regenie_step2_dir}/{regenie_step2_prefix}_c*_singlevariant_step2_{pheno}.regenie"
        fs_output = subprocess.run(fs_cmd, shell=True, capture_output=True, text=True)
        files = fs_output.stdout.split('\n')[:-1]
        # Sort files by chromosome number
        files.sort(key=get_chr_num)
        in_files = [f'-iin={regenie_step2_dir}/{file}' for file in files]
        
        # Create concatenation command that handles headers properly
        # First file: keep header, subsequent files: skip header (first line)
        if len(files) > 0:
            # Start with the first file (keeping its header)
            concat_cmd = f"cp {files[0]} {regenie_step2_prefix}_all_chr_singlevariant_step2_{pheno}.regenie"
            
            # Add subsequent files without their headers
            for file in files[1:]:
                concat_cmd += f" && tail -n +2 {file} >> {regenie_step2_prefix}_all_chr_singlevariant_step2_{pheno}.regenie"
        else:
            # If no files found, create empty output file
            concat_cmd = f"touch {regenie_step2_prefix}_all_chr_singlevariant_step2_{pheno}.regenie"
        
        dx_cmd = [
            'dx', 'run', 'swiss-army-knife',
            *in_files,
            f'-icmd={concat_cmd}',
            '--name', f'concat_regenie_singlevariant_step2_{pheno}',
            '--destination', output_dir,
            '--yes',
            '--wait'
        ]
        # Execute the dx command with error handling
        try:
            result = subprocess.run(dx_cmd, check=True)
        except subprocess.CalledProcessError as e:
            print(f"Error: Command failed with exit code {e.returncode}")
            sys.exit(1)
    
    
if __name__ == "__main__":
    main()