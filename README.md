# machine-learning


Package - attempt to pick otus, summarize taxa, summarize otu run alpha and beta diversity on both unrarefacted data and rarefacted data

./commands.sh [options] application [arguments]

-h, --help				      		show brief help

-i, --INPUT=input_file	      		specify an input file to run

-o, --DIR=output_dir 		      		specify a output directory

-l, --LOG=log_file		      		specify a log file to report

-p, --PY=path_of_ninja.py       		specify the path of ninja.py

-t, --TREE=reference_tree      		specify the tree of otu reference

-s, --SIM=similarity   		      		specify the minimum percent similarity

-d, --DB=base directory of code   	specify the environment

Make sure the dataset directory(i.e. the directory that contains the input fna file) has the same name with the dataset itself. Also, the -d for the base directory should be the directory that contains the bin and data directories.

The script would run all the analysis with non-rarefaction at first and gives an suggested rarefaction depth, then the user inputs a expected depth to continue the script with all the analysis with rarefaction.