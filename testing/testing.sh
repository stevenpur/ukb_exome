dx run swiss-army-knife \
    -icmd="echoasfdas 'Hello World'" \
    --instance-type mem1_ssd1_v2_x16 \
    --yes \
    --brief \
    --wait


if [ $? -eq 0 ]; then
  echo "🎉 Job succeeded"
else
  echo "❌ Job failed"
fi