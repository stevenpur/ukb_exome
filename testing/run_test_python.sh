dx run swiss-army-knife -iin="/users/steven/test_python.py" -icmd="python test_python.py" --destination="${HOME}/ukb_rap/ukb_exome/testing" --wait --yes

cmd="python test_python.py"

cmd2="echo 'hi';
echo 'hi2'"

dx run app-dxjupyterlab_spark_cluster -iin="/users/steven/ind_qc.py" -cmd="python ind_qc.py"  --wait --yes