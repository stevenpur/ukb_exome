library(qqman)

phenotypes = c('acc-overall-avg', 'Cadence95thAdjustedStepsPerMin', 'moderate-vigorous-overall-avg', 'StepsDayAvgAdjusted')

for (phenotype in phenotypes) {
    message(paste0("Processing ", phenotype, "..."))
     in_file = paste0('~/ukb_rap/ukb_exome/analysis/nf_log/latest/dx_download/', 
                     phenotype, '_all_chr_singlevariant_step2.regenie')
    # in_file = paste0('~/ukb_rap/ukb_exome/analysis/nf_log/latest/dx_download/gt_merged_chr_qc_pruned_regenie_step1_all_chr_step2_', phenotype, '.regenie')
    # remove the comment lines first 
    cmd <- paste0("awk '$0 !~ /^#/ {print $0}' ", in_file, " | awk 'NR==1 || $1 != \"CHROM\"' > ",
                 in_file, ".clean")
    system(cmd)
    df = read.table(paste0(in_file, '.clean'), header = TRUE, sep = ' ')
    df$mac <- map_dbl(1:nrow(df), function(i) {
        maf <- df$A1FREQ[i]
        N <- df$N[i]
        if (maf > 0.5) {
            maf <- 1 - maf
        } 
        mac <- 2 * N * maf
        return(mac)
    })
    df <- df[df$mac > 10, ]
    threshold = -log10(0.05/nrow(df))
    print(paste0("Threshold: ", threshold))
    png(paste0("~/ukb_rap/ukb_exome/github/postanalysis/manhattan_singlevar", phenotype, ".png"),
        width  = 1600,   # width in pixels
        height =  900,   # height in pixels
        res    = 150)    # resolution (ppi)
    manhattan(df, chr = "CHROM", bp = "GENPOS", p = "LOG10P", snp = "ID", suggestiveline = FALSE, genomewideline = threshold, logp = FALSE)
    dev.off()
}
