import gzip
import os

file = "/mnt/project/users/steven/ukb23158_500K_OQFE_chr1.sets.txt.gz"
output = "ukb23158_500K_OQFE_chr1.sets.varid.txt"  # Writing to current directory

# read the file gzip file
with gzip.open(file, "rt") as f:
    with open(output, "w") as out:
        for line in f:
            line = line.strip().split('\t')
            snps = line[3].split(',')
            for snp in snps:
                # write the snp to the output file
                out.write(snp + '\n')



