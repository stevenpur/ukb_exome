dx run swiss-army-knife -iin="/users/steven/test_python.py" -icmd="python test_python.py" --destination="${HOME}/ukb_rap/ukb_exome/testing" --wait --yes

cmd="python test_python.py"

cmd2="echo 'hi';
echo 'hi2'"

dx run app-dxjupyterlab_spark_cluster -iin="/users/steven/ind_qc.py" -cmd="python ind_qc.py"  --wait --yes


Right... now I need to test what is causing no show

So I need the subset of the variable in the gene set and check their frequency in the plink files

how do I extract the subset of the variable in the gene set and check their frequency in the plink files?