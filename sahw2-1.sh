ls -ARl | grep '^[-|d]' | sort -rnk5 | awk '$1 ~ /^-/{{fileNum++;}{total+=$5;}} $1 ~ /^d/ {dirNum++;} NR<=5 {print NR ":" $5, $9;} END{print "Dir num: " dirNum "\nFile num: " fileNum "\nTotal: " total;}'