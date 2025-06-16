#!/usr/bin/env python3

import argparse
import pandas as pd
import numpy as np

def parse_args():
    parser = argparse.ArgumentParser(description='Get significant hits from REGENIE results')
    parser.add_argument('--assoc', required=True, help='Association file')
    parser.add_argument('--output', required=True, help='Output file')
    parser.add_argument('--pval_col', default='LOG10P', help='P-value column name (default: LOG10P)')
    parser.add_argument('--sep', default=' ', help='Separator character (default: space)')
    return parser.parse_args()

def main():
    args = parse_args()
    
    # Read association file
    df = pd.read_csv(args.assoc, sep=args.sep, comment="#", header = 0)
    print(f"Number of columns: {len(df.columns)}")
    print(f"Number of rows: {len(df)}")
    # Print data type of each column
    print("\nColumn datatypes:")
    for col in df.columns:
        print(f"{col}: {df[col].dtype}")
    # Print first 10 p-values and their data type
    print("\nFirst 10 p-values:")
    print(df[args.pval_col].head(10))
    print(f"\nP-value column data type: {df[args.pval_col].dtype}")
    # Ensure p-value column exists
    if args.pval_col not in df.columns:
        raise ValueError(f"P-value column '{args.pval_col}' not found in input file")

    # Check if p-value column is log transformed
    is_log = any(x in args.pval_col.lower() for x in ['log', 'LOG'])
    print(f"P-value column: {args.pval_col}")
    if is_log:
        print(f"P-value column is log transformed")
    else:
        print(f"P-value column is not log transformed")
    
    df[args.pval_col] = pd.to_numeric(df[args.pval_col], errors='coerce')

    # bonferroni correction
    bonf_pval = 0.05 / len(df)
    if not is_log:
        print(f"Bonferroni corrected p-value: {bonf_pval}")
        sig_hits = df[df[args.pval_col] < bonf_pval]
    else:
        bonf_pval = -1 * np.log10(bonf_pval)
        print(f"Bonferroni corrected p-value (log transformed): {bonf_pval}")
        sig_hits = df[df[args.pval_col] > bonf_pval]

    print(f"Number of significant hits: {len(sig_hits)}")

    # Write significant hits to file
    with open(args.output, 'w') as f:
        f.write(f"# Significance threshold: p < {bonf_pval}\n")
    sig_hits.to_csv(args.output, sep=' ', index=False, mode='a')
    

if __name__ == "__main__":
    main()
