# set up conda environment for UKB RAP run

# check if conda environment ukb_rap exists
echo "checking if ukb_rap environment exists..."
if conda env list | grep -q "ukb_rap"; then
    echo "ukb_rap environment exists"
else
    echo "ukb_rap environment does not exist"
    echo "creating ukb_rap environment"
    conda env create -f ukb_rap.yml
fi

# activate ukb_rap environment
echo "activating ukb_rap environment"
conda activate ukb_rap