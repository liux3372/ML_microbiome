#!/bin/bash
#chomod +x commands.sh
#macqiime
echo "Running couple of commands…" #run this script in the dataset folder
#Picking Otus:
#PY="/Users/xinyuan/Desktop/MICE8992/ninja/bin/ninja.py"
PY=
#tree:
#TREE="/macqiime/anaconda/lib/python2.7/site-packages/qiime_default_reference/gg_13_8_otus/trees/97_otus.tree"
TREE=
#assign_taxonomy:
SIM=0.97
#INPUT="Claesson_elderly_gut_study_486_ref_13_8/Claesson_elderly_gut_study_486_split_library_seqs.fna"
INPUT=
OUTPUT=
LOG="log.txt"
DB=
while [ $# -gt 0 ]
do
    case "$1" in
    -i)  INPUT="$2"; shift;;
	--)	shift; break;;
	-o)  OUTPUT="$2"; shift;;
	--)	shift; break;;
	-l)  LOG="$2"; shift;;
	--)	shift; break;;
	-p)  PY="$2"; shift;;
	--)	shift; break;;
	-t)  TREE="$2"; shift;;
	--)	shift; break;;
	-s)  SIM="$2"; shift;;
	--)	shift; break;;
	-d)  DB="$2"; shift;;
	--)	shift; break;;
	-h) echo "package - attempt to pick otus, summarize taxa, summarize otu run alpha and beta diversity on both unrarefacted data and rarefacted data"
		echo " "
		echo "./commands.sh [options] application [arguments]"
		echo " "
		echo "options:"
		echo "-h, --help				     		show brief help"
		echo "-i, --INPUT=input_file	     		specify an input file to run"
		echo "-o, --DIR=output_dir 		     		specify a output directory"
		echo "-l, --LOG=log_file		     		specify a log file to report"
		echo "-p, --PY=path_of_ninja.py      		specify the path of ninja.py"
		echo "-t, --TREE=reference_tree      		specify the tree of otu reference"
		echo "-s, --SIM=similarity   		 		specify the minimum percent similarity"
		echo "-d, --DB=base directory of code   	specify the environment variable"
		exit 0;;
	*)  break;;	# terminate while loop
    esac
    shift
done

#set environment variable
export MLDB="$DB"
#cd ../data/
# echo "$INPUT"
# echo "$OUTPUT"
# echo "$LOG"
#the variable used to rename the output files based on the name of the dataset
FOLDER="$(basename $OUTPUT)"
#FOLDER="$(basename "$(dirname "$INPUT")")"
ENV="$(dirname "$INPUT")"

DES="$(dirname "$OUTPUT")"
#echo "$OUTPUT"
cd "$DES"
#create the log file
> "$LOG"
mkdir $OUTPUT
#cd "$ENV"

#it depends on if you have permission to modify on the dataset folder or not
#cd $FOLDER
#cd 

#FNA=$(basename $INPUT)
#use -r on ninja when the sequences are reversed
python $PY -i "$INPUT" -o ninja -s $SIM>>$LOG 2>&1
#mv "$LOG" $FOLDER
ERROR_READING="Total reads expanded: 0"
if grep -Fxq "$ERROR_READING" "$LOG";
	then
		echo "reversed sequences">>$LOG 2>&1
		rm -r ninja
		python $PY -i "$INPUT" -o ninja -r -s $SIM>>$LOG 2>&1
fi 
#reference:
#print_qiime_config.py
BIOM="ninja/ninja_otutable.biom"
#move ninja_otutable.biom to the output folder and rename it to the name of the dataset 
NEW_BIOM="$OUTPUT/$FOLDER.biom"
mv "$BIOM" "$NEW_BIOM"
#Summarize the OTU table(non-rarefaction):
SUM="ninja/otu_summary.txt"
echo "biom summarize-table -i $NEW_BIOM -o $SUM">>$LOG 2>&1
biom summarize-table -i $NEW_BIOM -o $SUM>>$LOG 2>&1
#the original file is used by the depth.py
cp "$SUM" "$OUTPUT/"

#Summarizing Taxonomy(non-rarefaction):

TAX="$OUTPUT/taxonomy_summaries/"
for i in {1..7}
do
echo "summarize_taxa.py -i $NEW_BIOM -o $TAX -L $i">>$LOG 2>&1
summarize_taxa.py -i $NEW_BIOM -o $TAX -L $i >>$LOG 2>&1
done
# mv "$TAX" "$PWD/$OUTPUT/"
#Calculating Alpha Diversity(non-rarefaction):
#adiv_chao1.txt
#adiv_observed_otus.txt
cd $OUTPUT
mkdir alpha_div
cd ../
ALPHA="$OUTPUT/alpha_div/alphadiv.txt"
#ALPHA2="ninja/adiv/"
echo "alpha_diversity.py -i $NEW_BIOM -t $TREE -o $ALPHA">>$LOG 2>&1
alpha_diversity.py -i $NEW_BIOM -t $TREE -o $ALPHA>>$LOG 2>&1
#mv "$ALPHA" "$PWD/$OUTPUT/"
#Calculating Beta Diversity(non-rarefaction):


BETA="$OUTPUT/beta_div/"
echo "beta_diversity.py -i $NEW_BIOM -m weighted_unifrac -o $BETA -t $TREE">>$LOG 2>&1
echo "beta_diversity.py -i $NEW_BIOM -m unweighted_unifrac -o $BETA -t $TREE">>$LOG 2>&1
echo "beta_diversity.py -i $NEW_BIOM -m bray_curtis -o $BETA -t $TREE">>$LOG 2>&1
beta_diversity.py -i $NEW_BIOM -m weighted_unifrac -o $BETA -t $TREE>>$LOG 2>&1
beta_diversity.py -i $NEW_BIOM -m unweighted_unifrac -o $BETA -t $TREE>>$LOG 2>&1
beta_diversity.py -i $NEW_BIOM -m bray_curtis -o $BETA -t $TREE>>$LOG 2>&1

BETA_WEIGHTED="$OUTPUT/beta_div/weighted_unifrac_dm.txt"
BETA_UNWEIGHTED="$OUTPUT/beta_div/unweighted_unifrac_dm.txt"
BETA_BRAY="$OUTPUT/beta_div/braycurtis_dm.txt"
mv "$OUTPUT/beta_div/weighted_unifrac_$FOLDER.txt" "$BETA_WEIGHTED" 
mv "$OUTPUT/beta_div/unweighted_unifrac_$FOLDER.txt" "$BETA_UNWEIGHTED" 
mv "$OUTPUT/beta_div/bray_curtis_$FOLDER.txt" "$BETA_BRAY"

#Performing rarefactions:
NEW_BIOM_R="$OUTPUT/${FOLDER}_rare.biom"
#cd ../../bin/
python_file="$MLDB/bin/depth.py"
cp $python_file .
#cd $FOLDER
#BIOM_R="ninja/ninja_otutable_rare.biom"
#INPUT="Gevers_CCFA_RISK_study_1939_gg_ref_13_8/Gevers_CCFA_RISK_study_1939_split_library_seqs.fna"
depth=$(python depth.py 2>&1)

echo "suggested rarefaction depth: $depth"
echo "Please input the expected depth:"
read depth
#python_file="depth.py"
#echo $depth
echo "single_rarefaction.py -i $NEW_BIOM -o $NEW_BIOM_R -d $depth">>$LOG 2>&1
single_rarefaction.py -i $NEW_BIOM -o $NEW_BIOM_R -d $depth>>$LOG 2>&1
#Summarize the OTU table(rarefaction):
SUM_R="ninja/otu_summary_rare.txt"
echo "biom summarize-table -i $NEW_BIOM_R -o $SUM_R">>$LOG 2>&1
biom summarize-table -i $NEW_BIOM_R -o $SUM_R>>$LOG 2>&1
cp "$SUM_R" "$OUTPUT/"

#Summarizing Taxonomy(rarefaction):
TAX_R="$OUTPUT/taxonomy_summaries_rare/"
for i in {1..7}
do
echo "summarize_taxa.py -i $NEW_BIOM_R -o $TAX_R -L $i">>$LOG 2>&1
summarize_taxa.py -i $NEW_BIOM_R -o $TAX_R -L $i >>$LOG 2>&1
done
# mv "$TAX_R" "$PWD/$OUTPUT/"
#Calculating Alpha Diversity(rarefaction):
cd $OUTPUT
mkdir alpha_div_rare
cd ../
ALPHA_R="$OUTPUT/alpha_div_rare/alphadiv_rare.txt"
echo "alpha_diversity.py -i $NEW_BIOM_R -t $TREE -o $ALPHA_R">>$LOG 2>&1
alpha_diversity.py -i $NEW_BIOM_R -t $TREE -o $ALPHA_R>>$LOG 2>&1
# mv "$ALPHA_R" "$PWD/$OUTPUT/"
#Calculating Beta Diversity(rarefaction):
BETA_R="$OUTPUT/beta_div_rare/"
echo "beta_diversity.py -i $NEW_BIOM_R -m weighted_unifrac -o $BETA_R -t $TREE">>$LOG 2>&1
echo "beta_diversity.py -i $NEW_BIOM_R -m unweighted_unifrac -o $BETA_R -t $TREE">>$LOG 2>&1
echo "beta_diversity.py -i $NEW_BIOM_R -m bray_curtis -o $BETA_R -t $TREE">>$LOG 2>&1
beta_diversity.py -i $NEW_BIOM_R -m weighted_unifrac -o $BETA_R -t $TREE>>$LOG 2>&1
beta_diversity.py -i $NEW_BIOM_R -m unweighted_unifrac -o $BETA_R -t $TREE>>$LOG 2>&1
beta_diversity.py -i $NEW_BIOM_R -m bray_curtis -o $BETA_R -t $TREE>>$LOG 2>&1

BETA_WEIGHTED="$OUTPUT/beta_div_rare/weighted_unifrac_dm_rare.txt"
BETA_UNWEIGHTED="$OUTPUT/beta_div_rare/unweighted_unifrac_dm_rare.txt"
BETA_BRAY="$OUTPUT/beta_div_rare/braycurtis_dm_rare.txt"
mv "$OUTPUT/beta_div_rare/weighted_unifrac_${FOLDER}_rare.txt" "$BETA_WEIGHTED" 
mv "$OUTPUT/beta_div_rare/unweighted_unifrac_${FOLDER}_rare.txt" "$BETA_UNWEIGHTED" 
mv "$OUTPUT/beta_div_rare/bray_curtis_${FOLDER}_rare.txt" "$BETA_BRAY"
# mv "$BETA_R" "$PWD/$OUTPUT/"
NINJA_LOG="ninja/ninja_log.txt"
#move ninja_log file to output folder
mv "$NINJA_LOG" "$OUTPUT/"
rm -rf ninja
#move log file to output folder
mv "$LOG" "$OUTPUT/"
#remove depth.py
#rm "depth.py"
#mv "depth.py" "../../bin"
#cd ../



#log file is now in the current directory



#Aligning Sequences:
#align_seqs.py -i study_850_split_library_seqs.fna -o alignment/
#Building a phylogeny tree:
#make_phylogeny.py -i alignment/rep_set_aligned_pfiltered.fasta -o rep_set_tree.tre