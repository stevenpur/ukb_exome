import pandas as pd
from scipy.stats import rankdata, norm
import numpy as np
import os
pheno_file = '/mnt/project/users/steven/pheno_step.csv'
pheno_file = '/mnt/project/users/steven/pheno_step_rint.csv'
pheno = pd.read_csv(pheno_file, sep=' ')

# rint the data
def rank_int(x):
    """
    Rank-inverse normal transform:
      1) rank data (average ranks for ties)
      2) scale ranks to (0,1)
      3) apply the standard normal quantile function
    keep the NaN values and ignore them
    """
    # Store original NaN positions
    is_nan = pd.isna(x)
    # Get non-NaN values
    x_nonnan = x[~is_nan]
    # Rank the non-NaN values, handling ties with average
    ranked = rankdata(x_nonnan)
    # Scale ranks to (0,1) using (rank - 0.5)/n
    n = len(x_nonnan)
    scaled = (ranked - 0.5) / n
    # Apply inverse normal transform
    transformed = norm.ppf(scaled)
    # Put results back into original array with NaNs preserved
    result = x.copy()
    result[~is_nan] = transformed
    return result
    # Get phenotype columns (excluding FID and IID)
pheno_cols = pheno.columns[2:]

# Apply rint transformation to each phenotype column
for col in pheno_cols:
    pheno[col] = rank_int(pheno[col])

# Write transformed data to new file
output_file = 'pheno_step_rint.csv'
pheno.to_csv(output_file, sep=' ', index=False, na_rep='NA')
# run dx upload command
cmd = f"dx upload {output_file} --path /users/steven/pheno_step_rint.csv"
os.system(cmd)
