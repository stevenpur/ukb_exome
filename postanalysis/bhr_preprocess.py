import gzip
import os
import argparse
import sys

def build_pos_to_gene_annot(annot_file = '/Bulk/Exome sequences/Population level exome OQFE variants, PLINK format - final release/helper_files/ukb23158_500k_OQFE.annotations.txt.gz'):
    pos_to_gene_annot = {}
    with gzip.open(annot_file, 'rt') as f:
        for line in f:
            if line.startswith('#'):
                continue
            line = line.strip().split(' ')
            var_id = line[0]
            gene = line[1]
            ensembl_id = gene.split('(')[1].replace(')', '')
            annot = line[2]
            pos_to_gene_annot[var_id] = [ensembl_id, annot]
    return pos_to_gene_annot

def build_gene_to_genepos(gen_annot_file = '/Bulk/Exome sequences/Population level exome OQFE variants, PLINK format - final release/helper_files/ukb23158_500k_OQFE.sets.txt.gz'):
    gene_to_genepos = {}
    with gzip.open(gen_annot_file, 'rt') as f:
        for line in f:
            if line.startswith('#'):
                continue
            line = line.strip().split('\t')
            gene = line[0]
            ensembl_id = gene.split('(')[1].replace(')', '')
            chrom = line[1]
            pos = line[2]
            gene_to_genepos[ensembl_id] = f'{chrom}:{pos}'
    return gene_to_genepos

def preprocess_file_for_bhr(input_file, output_file, pos_to_gene_annot, gene_to_genepos):
    """
    Preprocess a single association file to BHR input format.
    
    Args:
        input_file (str): Path to the input association file
        output_file (str): Path to the output BHR-ready file
        pos_to_gene_annot (dict): Dictionary mapping variant IDs to gene annotations
        gene_to_genepos (dict): Dictionary mapping gene IDs to positions
    """
    if not os.path.exists(input_file):
        raise FileNotFoundError(f'{input_file} does not exist')
    
    print(f'Processing {input_file}...')
    
    with open(output_file, 'w') as o:
        with open(input_file, 'r') as f:
            # read the header and change the column names to meet BHR input format
            header = f.readline().strip()
            header = header.replace('A1FREQ', 'AF')
            header = header.replace('CHROM', 'chromosome')
            header = header.replace('BETA', 'beta')
            header = header.split(' ')
            header.append('gene')
            header.append('gene_position')
            header.append('gene_annot')
            _ = o.write('\t'.join(header) + '\n')
            
            # add gene, gene_position, and gene_annot to the output files
            for line in f:
                line = line.strip().split(' ')
                var_id = line[2]
                if var_id in pos_to_gene_annot:
                    gene, annot = pos_to_gene_annot[var_id]
                    gene_pos = gene_to_genepos[gene]
                    gene_pos_bp = gene_pos.split(':')[1]
                else:
                    continue
                line.append(gene)
                line.append(gene_pos_bp)
                line.append(annot)
                _ = o.write('\t'.join(line) + '\n')
    
    print(f'Output written to {output_file}')

def main():
    parser = argparse.ArgumentParser(description='Preprocess association files to BHR input format')
    parser.add_argument('input_file', help='Path to the input association file')
    parser.add_argument('--annot_file', 
                       default='/mnt/project/Bulk/Exome sequences/Population level exome OQFE variants, PLINK format - final release/helper_files/ukb23158_500k_OQFE.annotations.txt.gz',
                       help='Path to the annotation file (default: UKB annotation file)')
    parser.add_argument('--gen_annot_file',
                       default='/mnt/project/Bulk/Exome sequences/Population level exome OQFE variants, PLINK format - final release/helper_files/ukb23158_500k_OQFE.sets.txt.gz',
                       help='Path to the gene annotation file (default: UKB gene sets file)')
    parser.add_argument('--output_file',
                       help='Path to the output BHR-ready file')
    
    args = parser.parse_args()
    
    # Check if input file exists
    if not os.path.exists(args.input_file):
        print(f"Error: Input file '{args.input_file}' does not exist")
        sys.exit(1)
    
    # Build annotation dictionaries
    print("Building annotation dictionaries...")
    pos_to_gene_annot = build_pos_to_gene_annot(args.annot_file)
    gene_to_genepos = build_gene_to_genepos(args.gen_annot_file)
    
    # Preprocess the file
    try:
        preprocess_file_for_bhr(args.input_file, args.output_file, pos_to_gene_annot, gene_to_genepos)
        print(f"Successfully processed {args.input_file}")
        print(f"BHR-ready file saved to: {args.output_file}")
    except Exception as e:
        print(f"Error processing file: {e}")
        sys.exit(1)

if __name__ == "__main__":
    main()
