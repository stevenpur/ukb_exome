# install the packages needed for the analysis
message('*** Installing packages, this may take 20 minutes! ***')
if(!require(pacman)) install.packages("pacman")
pacman::p_load(reticulate, dplyr, parallel, bigsnpr, ggplot2, readr, bigparallelr, hexbin, skimr, tidyverse, arrow)
message('*** Finished installing packages! ***')


