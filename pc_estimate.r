message('*** Installing packages, this may take 20 minutes! ***')
if(!require(pacman)) install.packages("pacman")
pacman::p_load(reticulate, dplyr, parallel, bigsnpr, ggplot2, readr, bigparallelr, hexbin, skimr, tidyverse, arrow)
message('*** Finished installing packages! ***')

read_pca_ind <- function(file) {
    # read the file with the individuals to be used in the PCA
    read.table(file, sep = "\t", header = TRUE, stringsAsFactors = FALSE)
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
  install_and_load_packages()
  pca_ind <- read_pca_data(data_path)
  genotypes_smpl <- process_genotypes(data_path, pca_ind)
  pca_results <- compute_pca(genotypes_smpl$genotypes)

  # Additional code to handle PCA results goes here

  return(pca_results)
}

data_path <- "/mnt/project/users/stevenpur/exom_test/"
pca_ind_file <- paste0(data_path, "testing_pca.tsv")
pca_ind <- read.table(pca_ind_file, sep = "\t", header = T, stringsAsFactors = F)

# read the gentoype file
geno_file <- paste0(data_path, "ukb22418_merged_c1_22_v2_merged_qc_pruned.bed")
fam_file <- paste0(data_path, "ukb22418_merged_c1_22_v2_merged_qc_pruned.fam")

fam_eid <- read_delim(fam_file,
                col_names = c('FID', 'IID', 'father', 'mother', 'sex', 'phenotype'),
                show_col_types = FALSE) %>% 
    pull(IID) %>% 
    as.character

tmpfile <- normalizePath("bigsnpr_input", mustWork = F)
if(length(dir(pattern=tmpfile)) ) unlink(dir(pattern=tmpfile))

snp_readBed2(geno_file, backingfile = tmpfile, ind.row=which(fam_eid %in% pca_ind$IID))

genotypes_smpl <- snp_attach(paste0(tmpfile, ".rds"))
names(genotypes_smpl)


options(bigstatsr.check.parallel.blas = FALSE)
NCORES = nb_cores()
assert_cores(NCORES)
message('INFO: Using ', NCORES, ' cores')

G   <- genotypes_smpl$genotypes
CHR <- genotypes_smpl$map$chromosome
POS <- genotypes_smpl$map$physical.pos
obj.svd <- big_randomSVD(G, fun.scaling = snp_scaleBinom(), ncores = NCORES)
