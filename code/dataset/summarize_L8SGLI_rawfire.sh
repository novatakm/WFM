#!/usr/bin/env bash

usage() {
    echo $(basename $0)
	echo "-o <output_summary_file>"
    echo "-g <GISDBASE_name>"
    exit 0
}

tmpfn=$$

while getopts o:g:h OPT
do
    case $OPT in
	o)
		OUT_FILE=$OPTARG
		;;
	g)
	    GISDBASE=$OPTARG
	    ;;
	h)
	    usage
	    ;;
	\?)
	    usage
	    ;;
    esac
done

if [ "$GISDBASE" = "" ]; then
    GISDBASE=$( g.gisenv GISDBASE )
fi
mkdir -p $( dirname $OUT_FILE )

g.list rast p="GC1SG1_*_LC08_*" | cat | awk '{print "echo "$1, ";g.region rast="$1, "; r.univar -g "$1, "; echo \"\""}' | sh > /tmp/tmp$tmpfn
cat /tmp/tmp$tmpfn | awk 'BEGIN{RS=""; FS="\n"; OFS=","}{print $1,$2,$8,"0"}' | sed 's:[n=|mean=]::g' > $OUT_FILE
rm /tmp/tmp$tmpfn