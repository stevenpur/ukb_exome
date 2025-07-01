import gzip
import os

# Test the annotation file format
annot_file = '/mnt/project/Bulk/Exome sequences/Population level exome OQFE variants, PLINK format - final release/helper_files/ukb23158_500k_OQFE.annotations.txt.gz'
gen_annot_file = '/mnt/project/Bulk/Exome sequences/Population level exome OQFE variants, PLINK format - final release/helper_files/ukb23158_500k_OQFE.sets.txt.gz'

print("=== Testing Annotation File ===")
if os.path.exists(annot_file):
    try:
        with gzip.open(annot_file, 'rt') as f:
            for i, line in enumerate(f):
                if i < 5:  # Show first 5 lines
                    print(f"Line {i+1}: {line.strip()}")
                else:
                    break
    except Exception as e:
        print(f"Error reading annotation file: {e}")
else:
    print(f"Annotation file not found: {annot_file}")

print("\n=== Testing Gene Position File ===")
if os.path.exists(gen_annot_file):
    try:
        with gzip.open(gen_annot_file, 'rt') as f:
            for i, line in enumerate(f):
                if i < 5:  # Show first 5 lines
                    print(f"Line {i+1}: {line.strip()}")
                else:
                    break
    except Exception as e:
        print(f"Error reading gene position file: {e}")
else:
    print(f"Gene position file not found: {gen_annot_file}")

print("\n=== Testing Association Files ===")
phenotypes = ['acc-overall-avg', 'Cadence95thAdjustedStepsPerMin', 'moderate-vigorous-overall-avg', 'StepsDayAvgAdjusted']

for phenotype in phenotypes:
    assoc_file = f'/mnt/project/users/steven/nf_test_04062025/{phenotype}_all_chr_singlevariant_step2.regenie'
    print(f"\n--- {phenotype} ---")
    if os.path.exists(assoc_file):
        try:
            with open(assoc_file, 'r') as f:
                # Show header
                header = f.readline().strip()
                print(f"Header: {header}")
                print(f"Header parts: {header.split(' ')}")
                
                # Show first few data lines
                for i, line in enumerate(f):
                    if i < 3:  # Show first 3 data lines
                        print(f"Data line {i+1}: {line.strip()}")
                        print(f"Data parts: {line.strip().split(' ')}")
                    else:
                        break
        except Exception as e:
            print(f"Error reading association file: {e}")
    else:
        print(f"Association file not found: {assoc_file}") 