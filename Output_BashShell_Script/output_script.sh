fgrep .als hosts.db | awk -F: '{if ($10 > 0) {print $1,$9,$10}}' | awk '{count++ ; sum+=$3 ; print $0} END{print "\nsum=", sum ; print "count=", count; print "\n\n\n"}' > out1
fgrep .als hosts.db | awk -F: '{if ($10 == 0) {print $1,$9,$10}}' | awk '{count++ ; print $0} END{print "\ncount=", count}' > out2
cat out1 out2 > output
rm out1
rm out2