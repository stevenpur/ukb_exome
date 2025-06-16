import subprocess
regenie_step1_dir = "/users/steven/nf_test_04062025/"
regenie_step1_prefix = "gt_merged_chr_qc_pruned_regenie_step1"
cmd = f"dx ls {regenie_step1_dir}/{regenie_step1_prefix}*.loco"
loco_files = subprocess.check_output(cmd, shell=True).decode('utf-8').strip().split('\n')
loco_files = [f"-iin={regenie_step1_dir}/{file}" for file in loco_files]
print(loco_files)