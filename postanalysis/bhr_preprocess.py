import gzip

# the path needs to be adjusted to be run by swiss-army-knife later
# right now, we focus on LoF only
annot_file = '/mnt/project/Bulk/Exome sequences/Population level exome OQFE variants, PLINK format - final release/helper_files/ukb23158_500k_OQFE.annotations.txt.gz'
gen_annot_file = '/mnt/project/Bulk/Exome sequences/Population level exome OQFE variants, PLINK format - final release/helper_files/ukb23158_500k_OQFE.sets.txt.gz'

assoc_file = '/mnt/project/users/steven/nf_test_04062025/Cadence95thAdjustedStepsPerMin_all_chr_singlevariant_step2.regenie'

output_file = 'bhr_input_Cadence95thAdjustedStepsPerMin_annotated.tsv'
# load data and build pos_to_gene dict
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
    
# load assoc file and reformat it to BHR input format
with open(output_file, 'w') as o:
    with open(assoc_file, 'r') as f:
        # read the header
        header = f.readline().strip()
        header = header.replace('A1FREQ', 'AF')
        header = header.replace('CHROM', 'chromosome')
        header = header.replace('BETA', 'beta')
        header = header.split(' ')
        header.append('gene')
        header.append('gene_position')
        header.append('gene_annot')
        print('\t'.join(header))
        o.write('\t'.join(header) + '\n')
        for line in f:
             line = line.strip().split(' ')
             var_id = line[2]
             if var_id in pos_to_gene_annot:
                 gene, annot = pos_to_gene_annot[var_id]
                 gene_pos = gene_to_genepos[gene]
             else:
                 continue
             line.append(gene)
             line.append(gene_pos)
             line.append(annot)
             o.write('\t'.join(line) + '\n')
