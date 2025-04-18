read_pca_ind <- function(file, col_name) {
    # read the file with the individuals to be used in the PCA
    tb <- read.table(file, sep = "\t", header = TRUE, stringsAsFactors = FALSE)
    id <- as.character(tb[, col_name])
    return(id)
}

read_fam_data <- function(file) {
    # get the individuals in the genotype file
    read_delim(file, col_names = c('FID', 'IID', 'father', 'mother', 'sex', 'phenotype'), show_col_types = FALSE) %>% 
        pull(IID) %>% 
        as.character
}

process_genotypes <- function(geno_file, pca_ind) {
    # read the gentoype file
    fam_eid <- read_fam_data(data_path)
    # create a temporary file to store the genotypes
    tmpfile <- normalizePath("bigsnpr_input", mustWork = FALSE)
    if(length(dir(pattern = tmpfile))) unlink(dir(pattern = tmpfile))
    # read the genotypes
    snp_readBed2(geno_file, backingfile = tmpfile, ind.row = which(fam_eid %in% pca_ind$IID))
    # Load a bigSNP from backing files into R
    genotypes_smpl <- snp_attach(paste0(tmpfile, ".rds"))
    names(genotypes_smpl)
}

compute_pca <- function(genotypes) {
  options(bigstatsr.check.parallel.blas = FALSE)
  NCORES <- nb_cores()
  assert_cores(NCORES)
  message('INFO: Using ', NCORES, ' cores')
  G <- genotypes
  obj.svd <- big_randomSVD(G, fun.scaling = snp_scaleBinom(), ncores = NCORES)
  obj.svd
}

perform_pca_analysis <- function(data_path) {
  pca_ind <- read_pca_data(data_path)
  genotypes_smpl <- process_genotypes(data_path, pca_ind)
  pca_results <- compute_pca(genotypes_smpl$genotypes)
  # Additional code to handle PCA results goes here
  return(pca_results)
}

# install the packages needed for the analysis
message('*** Installing packages, this may take 20 minutes! ***')
if(!require(pacman)) install.packages("pacman")
pacman::p_load(tidyverse)

#pacman::p_load(reticulate, dplyr, parallel, bigsnpr, ggplot2, readr, bigparallelr, hexbin, skimr, tidyverse, arrow)
#message('*** Finished installing packages! ***')

# get individuals in PCA reference
#ref_iid_file <-"testing_pca.tsv"
#ref_iid <- read_pca_ind(ref_iid_file, "IID")

# read the gentoype file
#bedfile <- paste0("ukb22418_merged_c1_22_v2_merged_qc_pruned.bed")
#obj.bed <- bed(bedfile)

# project the PCA from reference individuals to all individuals
#options(bigstatsr.check.parallel.blas = FALSE)
#ncores <- 15
#assert_cores(ncores)
#pca.project <- bed_projectPCA(
#  obj.bed,
#  obj.bed,
#  k = 10,
#  ind.row.ref = which(obj.bed$fam$sample.ID %in% ref_iid),
#  ncores = ncores
#)
# save the PCA results
saveRDS(pca.project, file = "pca_project.rds")