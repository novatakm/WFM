#!/usr/bin/env bash

usage(){
    echo $( basename $0 )
    echo "-g <GISDBASE name>"
    echo "-t <tile num. in VvvHhh format>"
    echo "-s <start_date (in yyyymmdd format)>"
    echo "-e <end_date (in yyyymmdd format)>"
    echo "-h help"
    exit
}

while getopts g:t:s:e:h  OPT
do
    case $OPT in
        g)
            GISDBASE=$OPTARG
        ;;
        t)
            TILE=$OPTARG
        ;;
        s)
            START_DATE=$OPTARG
        ;;
        e)
            END_DATE=$OPTARG
        ;;
        h)
            usage
        ;;
    esac
done

g.mapset map=INTMED loc=LL dbase=$GISDBASE

n_date=$( expr $( $DENV_TOOL/util/calc_datesubstr.sh $END_DATE $START_DATE ) + 1 )
obs_dates+=( $( jot $n_date 0 | xargs -I n date '+%Y%m%d' --date "n days $START_DATE") )

for obs_date in ${obs_dates[*]}
do
    
    
done