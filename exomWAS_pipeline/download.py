import argparse
import subprocess

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



def main():
    args = parse_args()
    regenie_step2_dir = read_first_line(args.regenie_step2_results)
    regenie_step2_prefix = '_'.join(read_last_line(args.regenie_step2_results).split('_')[:-2])
    output_dir = args.output_dir

    print(f"regenie step2 directory: {regenie_step2_dir}")
    print(f"regenie step2 prefix: {regenie_step2_prefix}")
    print(f"output directory: {output_dir}")

    phenos = args.pheno.split(',')
    fs = [f'{regenie_step2_dir}/{regenie_step2_prefix}_all_chr_step2_{pheno}.regenie' for pheno in phenos]

    subprocess.run(f"mkdir -p {output_dir}", shell=True)
    for f in fs:
        cmd = f"dx download {f} -o {output_dir}"
        subprocess.run(cmd, shell=True)

if __name__ == "__main__":
    main()