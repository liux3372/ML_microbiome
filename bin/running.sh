#!/bin/bash
#chmod +x commands.sh
#macqiime
INPUT=
OUTPUT=
MAP=
COL=
TIME=
DB=
while [ $# -gt 0 ]
do
    case "$1" in
    -i)  INPUT="$2"; shift;;
	--)	shift; break;;
	-o)  OUTPUT="$2"; shift;;
	--)	shift; break;;
	# -l)  LOG="$2"; shift;;
	# --)	shift; break;;
	-m)  MAP="$2"; shift;;
	--)	shift; break;;
	-c)  COL="$2"; shift;;
	--)	shift; break;;
	-t)  TIME="$2"; shift;;
	--)	shift; break;;
	-d)  DB="$2"; shift;;
	--)	shift; break;;
	-r)  RES="$2"; shift;;
	--)	shift; break;;
	-h) echo "script - attempt to run supervised learning"
		echo " "
		echo "./running.sh [options] application [arguments]"
		echo " "
		echo "options:"
		echo "-h, --help				     		show brief help"
		echo "-i, --INPUT=input_file	     		specify an input file to run"
		echo "-o, --DIR=output_dir 		     		specify a output directory"
		# echo "-l, --LOG=log_file		     		specify a log file to report"
		echo "-m, --MAP=mapping_file		     	specify a mapping file"
		echo "-c, --COL=column		     			specify the name of category to predict"
		echo "-t, --TIME=iteration				    specify the number of running"
		echo "-d, --DB=base directory of code   	specify the environment variable"
		echo "-r, --RES=directory of result  	 	specify the environment variable"
		exit 0;;
	*)  break;;	# terminate while loop
    esac
    shift
done
#set environment variable
export MLDB="$DB"
FOLDER="$(dirname $OUTPUT)"
cd $FOLDER
mkdir $RES
#> "$LOG"
#> "$STAT"
counter=1
until [ $counter -gt $TIME ]
do
STAT=$counter.txt
#supervised_learning.py -i "$INPUT" -m "$MAP" -c "$COL" -o "$OUTPUT" -f -e cv10
supervised_learning.py -i "$INPUT" -m "$MAP" -c "$COL" -o "$OUTPUT" -f
cd $OUTPUT
error_line=$(sed '3q;d' summary.txt)
#echo $error_line
error=$(echo "$error_line" | cut -d$'\t' -f2)
accuracy=$(echo "1-$error" | bc -l)
echo "$accuracy" > "$STAT"
cp "$STAT" $RES
cd ../
rm -rf $OUTPUT
((counter++))
done
#supervised_learning.py -i "$INPUT" -m "$MAP" -c "$COL" -o "$OUTPUT" -f -e cv10
supervised_learning.py -i "$INPUT" -m "$MAP" -c "$COL" -o "$OUTPUT" -f
cd $RES
cat *.txt > all.txt
r_file="$MLDB/bin/analysis.r"
cp $r_file .
./analysis.r
cd ..
cp log.txt "$OUTPUT"