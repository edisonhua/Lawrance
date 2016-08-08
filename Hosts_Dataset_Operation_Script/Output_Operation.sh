last -a > last-output.txt
awk '!($1 in a){a[$1];print}' < last-output.txt | awk '{print $1}' > namelist

name_to_exclude=(sdou root sjames kaisong yqin fernsler flexlm)
now="lastlogin-$(date +"%Y%m%d").txt"

awk '$4 == "Jan" {print $0}' < last-output.txt | sort -u -k1 > Jan.txt
awk '$4 == "Feb" {print $0}' < last-output.txt | sort -u -k1 > Feb.txt
awk '$4 == "Mar" {print $0}' < last-output.txt | sort -u -k1 > Mar.txt
awk '$4 == "Apr" {print $0}' < last-output.txt | sort -u -k1 > Apr.txt
awk '$4 == "May" {print $0}' < last-output.txt | sort -u -k1 > May.txt
awk '$4 == "Jun" {print $0}' < last-output.txt | sort -u -k1 > Jun.txt
awk '$4 == "Jul" {print $0}' < last-output.txt | sort -u -k1 > Jul.txt
awk '$4 == "Aug" {print $0}' < last-output.txt | sort -u -k1 > Aug.txt
awk '$4 == "Sep" {print $0}' < last-output.txt | sort -u -k1 > Sep.txt
awk '$4 == "Oct" {print $0}' < last-output.txt | sort -u -k1 > Oct.txt
awk '$4 == "Nov" {print $0}' < last-output.txt | sort -u -k1 > Nov.txt
awk '$4 == "Dec" {print $0}' < last-output.txt | sort -u -k1 > Dec.txt

awk -F'[ +:()]+' 'FNR==NR{a[$1]; next;} !($1 in a){next} NF==13{b[$1]+=$12/60+$11} NF==14{b[$1]+=$13/60+$12+24*$11} END{print "[Dec]"; for (n in b)print n,b[n],"hours"; print "\n"}' namelist Dec.txt > t12.txt
awk -F'[ +:()]+' 'FNR==NR{a[$1]; next;} !($1 in a){next} NF==13{b[$1]+=$12/60+$11} NF==14{b[$1]+=$13/60+$12+24*$11} END{print "[Jan]"; for (n in b)print n,b[n],"hours"; print "\n"}' namelist Jan.txt > t1.txt
awk -F'[ +:()]+' 'FNR==NR{a[$1]; next;} !($1 in a){next} NF==13{b[$1]+=$12/60+$11} NF==14{b[$1]+=$13/60+$12+24*$11} END{print "[Feb]"; for (n in b)print n,b[n],"hours"; print "\n"}' namelist Feb.txt > t2.txt
awk -F'[ +:()]+' 'FNR==NR{a[$1]; next;} !($1 in a){next} NF==13{b[$1]+=$12/60+$11} NF==14{b[$1]+=$13/60+$12+24*$11} END{print "[Mar]"; for (n in b)print n,b[n],"hours"; print "\n"}' namelist Mar.txt > t3.txt
awk -F'[ +:()]+' 'FNR==NR{a[$1]; next;} !($1 in a){next} NF==13{b[$1]+=$12/60+$11} NF==14{b[$1]+=$13/60+$12+24*$11} END{print "[Apr]"; for (n in b)print n,b[n],"hours"; print "\n"}' namelist Apr.txt > t4.txt
awk -F'[ +:()]+' 'FNR==NR{a[$1]; next;} !($1 in a){next} NF==13{b[$1]+=$12/60+$11} NF==14{b[$1]+=$13/60+$12+24*$11} END{print "[May]"; for (n in b)print n,b[n],"hours"; print "\n"}' namelist May.txt > t5.txt
awk -F'[ +:()]+' 'FNR==NR{a[$1]; next;} !($1 in a){next} NF==13{b[$1]+=$12/60+$11} NF==14{b[$1]+=$13/60+$12+24*$11} END{print "[Jun]"; for (n in b)print n,b[n],"hours"; print "\n"}' namelist Jun.txt > t6.txt
awk -F'[ +:()]+' 'FNR==NR{a[$1]; next;} !($1 in a){next} NF==13{b[$1]+=$12/60+$11} NF==14{b[$1]+=$13/60+$12+24*$11} END{print "[Jul]"; for (n in b)print n,b[n],"hours"; print "\n"}' namelist Jul.txt > t7.txt
awk -F'[ +:()]+' 'FNR==NR{a[$1]; next;} !($1 in a){next} NF==13{b[$1]+=$12/60+$11} NF==14{b[$1]+=$13/60+$12+24*$11} END{print "[Aug]"; for (n in b)print n,b[n],"hours"; print "\n"}' namelist Aug.txt > t8.txt
awk -F'[ +:()]+' 'FNR==NR{a[$1]; next;} !($1 in a){next} NF==13{b[$1]+=$12/60+$11} NF==14{b[$1]+=$13/60+$12+24*$11} END{print "[Sep]"; for (n in b)print n,b[n],"hours"; print "\n"}' namelist Sep.txt > t9.txt
awk -F'[ +:()]+' 'FNR==NR{a[$1]; next;} !($1 in a){next} NF==13{b[$1]+=$12/60+$11} NF==14{b[$1]+=$13/60+$12+24*$11} END{print "[Oct]"; for (n in b)print n,b[n],"hours"; print "\n"}' namelist Oct.txt > t10.txt
awk -F'[ +:()]+' 'FNR==NR{a[$1]; next;} !($1 in a){next} NF==13{b[$1]+=$12/60+$11} NF==14{b[$1]+=$13/60+$12+24*$11} END{print "[Nov]"; for (n in b)print n,b[n],"hours"; print "\n"}' namelist Nov.txt > t11.txt
awk -F'[ +:()]+' 'FNR==NR{a[$1]; next;} !($1 in a){next} NF==13{b[$1]+=$12/60+$11} NF==14{b[$1]+=$13/60+$12+24*$11} END{print "[TOTALS]"; for (n in b)print n,b[n],"hours"; print "\n"}' namelist last-output.txt > 1.txt

(IFS="|"; grep -vE "(${name_to_exclude[*]})" 1.txt > 1_new.txt)
(IFS="|"; grep -vE "(${name_to_exclude[*]})" t12.txt > t12_new.txt)
(IFS="|"; grep -vE "(${name_to_exclude[*]})" t1.txt > t1_new.txt)
(IFS="|"; grep -vE "(${name_to_exclude[*]})" t2.txt > t2_new.txt)
(IFS="|"; grep -vE "(${name_to_exclude[*]})" t3.txt > t3_new.txt)
(IFS="|"; grep -vE "(${name_to_exclude[*]})" t4.txt > t4_new.txt)
(IFS="|"; grep -vE "(${name_to_exclude[*]})" t5.txt > t5_new.txt)
(IFS="|"; grep -vE "(${name_to_exclude[*]})" t6.txt > t6_new.txt)
(IFS="|"; grep -vE "(${name_to_exclude[*]})" t7.txt > t7_new.txt)
(IFS="|"; grep -vE "(${name_to_exclude[*]})" t8.txt > t8_new.txt)
(IFS="|"; grep -vE "(${name_to_exclude[*]})" t9.txt > t9_new.txt)
(IFS="|"; grep -vE "(${name_to_exclude[*]})" t10.txt > t10_new.txt)
(IFS="|"; grep -vE "(${name_to_exclude[*]})" t11.txt > t11_new.txt)

awk '{total = total + $2} END {print "[GRAND TOTAL TIME]"; print total, "hours"}' 1_new.txt > grandtotal.txt

cat t12_new.txt t1_new.txt t2_new.txt t3_new.txt t4_new.txt t5_new.txt t6_new.txt t7_new.txt t8_new.txt t9_new.txt t10_new.txt t11_new.txt 1_new.txt grandtotal.txt > "$now"

rm namelist
rm Jan.txt Feb.txt Mar.txt Apr.txt May.txt Jun.txt Jul.txt Aug.txt Sep.txt Oct.txt Nov.txt Dec.txt
rm t1.txt t2.txt t3.txt t4.txt t5.txt t6.txt t7.txt t8.txt t9.txt t10.txt t11.txt t12.txt 1.txt
rm t1_new.txt t2_new.txt t3_new.txt t4_new.txt t5_new.txt t6_new.txt t7_new.txt t8_new.txt t9_new.txt t10_new.txt t11_new.txt t12_new.txt 1_new.txt grandtotal.txt


