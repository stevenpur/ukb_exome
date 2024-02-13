# Use an official R runtime as a parent image
FROM r-base

# Set the working directory in the container
WORKDIR /usr/src/app

# Install any needed packages specified in requirements.R
RUN Rscript -e "install.packages('reticulate')" \
    -e "install.packages('dplyr')" \
    -e "install.packages('parallel')" \
    -e "install.packages('bigsnpr')" \
    -e "install.packages('ggplot2')" \
    -e "install.packages('readr')" \
    -e "install.packages('bigparallelr')" \
    -e "install.packages('hexbin')" \
    -e "install.packages('skimr')" \
    -e "install.packages('tidyverse')" \
    -e "install.packages('arrow')"
    # Add as many packages as you need
    # -e "install.packages('packageN')"