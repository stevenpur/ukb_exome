
library(tidyverse)
library(bhr)

bhr_example_f <- '/users/doherty/imh310/ukb_rap/ukb_exome/bhr/reference_files/github_ms_variant_ss_400k_pLoF_group1_21001NA_BMI_munged.txt'
bhr_baseline_f <- '/users/doherty/imh310/ukb_rap/ukb_exome/data/ms_baseline_oe5.txt'

bhr_example <- read.table(bhr_example_f, header = TRUE, sep = ' ')
bhr_baseline <- read.table(bhr_baseline_f, header = TRUE, sep = ' ', row.names = 1)

# drop the variant_variance column
bhr_example <- bhr_example[, -which(colnames(bhr_example) == 'variant_variance')]

test_univariate <- BHR(mode='univariate',
                    trait1_sumstats = bhr_example,
                    annotations = list(bhr_baseline))







  2*bhr_input$AF*(1-bhr_input$AF)
