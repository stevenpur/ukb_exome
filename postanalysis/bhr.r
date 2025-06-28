
library(tidyverse)
library(bhr)

bhr_input_f <- '/users/doherty/imh310/ukb_rap/ukb_exome/analysis/nf_log/latest/dx_download/bhr_input_Cadence95thAdjustedStepsPerMin_annotated.tsv'
bhr_baseline_f <- '/users/doherty/imh310/ukb_rap/ukb_exome/data/ms_baseline_oe5.txt'

bhr_input <- read.table(bhr_input_f, header = TRUE, sep = '\t')
bhr_baseline <- read.table(bhr_baseline_f, header = TRUE, sep = ' ', row.names = 1)

# colnames(bhr_input)[which(colnames(bhr_input) == 'BETA')] <- 'beta'
# colnames(bhr_input)[which(colnames(bhr_input) == 'A1FREQ')] <- 'AF'
# colnames(bhr_input)[which(colnames(bhr_input) == 'CHROM')] <- 'chromosome'

reshep_bhr_input <- function(bhr_input, subrow=nrow(bhr_input)){
    bhr_input$phenotype_key <- 'Cadence95thAdjustedStepsPerMin'
    bhr_input$gene_position <- map_int(strsplit(bhr_input$gene_position, ':'), ~ as.integer(.[2]))
    bhr_input <- bhr_input[which(bhr_input$gene_annot == 'missense(5/5)'), ]
    bhr_input <- bhr_input[which(bhr_input$AF < 0.01 & bhr_input$AF > 0.001), ]
    bhr_input$variant_variance <- 1/ (bhr_input$N * bhr_input$SE^2)
    bhr_input <- bhr_input[, c('phenotype_key', 'chromosome', 'gene', 'gene_position', 'beta', 'AF', 'N', 'variant_variance')]
    bhr_input_sub <- bhr_input[1:subrow,]

    return(bhr_input_sub)
}


bhr_input_sub <- reshep_bhr_input(bhr_input)

test_univariate <- BHR(mode='univariate',
                    trait1_sumstats = bhr_input_sub,
                    custom_variant_variances = TRUE,
                    annotations = list(bhr_baseline))

