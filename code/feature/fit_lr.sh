#!/usr/bin/env bash

usage() {
    echo $(basename $0)
    echo "-i <dir in which input data is contained>"
    echo "-d <obs_date in YYYYMMDD[A|D] format>"
    echo "-s <subarea vector>"
    echo "-o <output directory for fitting parameter files>"
    exit 0
}

FN=$$

while getopts i:d:o:s:h OPT
do
    case $OPT in
        i)
            FIT_DATA_DIR=$OPTARG
        ;;
        d)
            OBS_DATE=$OPTARG
        ;;
        o)
            OUT_DIR=$OPTARG
        ;;
        s)
            SUBAREA=$OPTARG
        ;;
        h)
            usage
        ;;
        \?)
            usage
        ;;
    esac
done

out_dir=$OUT_DIR/$( basename $0 | sed 's:.sh$::g' )/$OBS_DATE/$SUBAREA/
mkdir -p $out_dir

for fit_data in $( ls $FIT_DATA_DIR/$OBS_DATE/$SUBAREA/ )
do
    
gnuplot -p << EOF 2> /dev/null
f(x) = a*x + b
set fit logfile "/tmp/fit$FN"
fit f(x) "$FIT_DATA_DIR/$OBS_DATE/$SUBAREA/$fit_data" u 1:2 via a, b
EOF
    
    fit_prm=$out_dir/$fit_data
    cat /tmp/fit$FN | grep -A3 'Final set of parameters' | tail -n2 | awk '{print $1$2$3}' > $fit_prm
    cat /tmp/fit$FN | grep -A2 'FIT_NDF' | awk 'BEGIN{FS=":"; prm[1]="ndf"; prm[2]="std_e"; prm[3]="var_e"}{print prm[NR]"="$NF}' | tr -d ' ' >> $fit_prm
    rm /tmp/fit$FN
done