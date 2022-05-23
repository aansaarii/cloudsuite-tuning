c_rate=`cat experiments/13/client-result.txt | grep "session-rate" | tail -1 | awk '{print $3}'`
g_rate=2
if (( $(echo "$c_rate > $g_rate * 0.5" | bc -l) )); then
  echo "reached the threshold"
else
  echo "not reached yet"
fi
