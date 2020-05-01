#!/usr/bin/env bash

usage(){
    echo $( basename $0 )
    echo "-g <GISDBASE name>"
    echo "-t <tile num. in VvvHhh format>"
    echo "-v <MCD14DL_vector name>"
    echo "-s <start_date (in yyyymmdd format)>"
    echo "-e <end_date (in yyyymmdd format)>"
    echo "-h help"
    exit
}

while getopts g:t:v:s:e:h  OPT
do
    case $OPT in
        g)
            GISDBASE=$OPTARG
        ;;
        t)
            TILE=$OPTARG
        ;;
        v)
            MCD14DL=$OPTARG
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
    $DENV_CODE/dataset/make_dataset_SGLI_for_manuinsp.sh \
    -r GC1SG1_${obs_date}D_${TILE}_RSW04_K,GC1SG1_${obs_date}D_${TILE}_RSW03_Q,GC1SG1_${obs_date}D_${TILE}_RVN11_Q,GC1SG1_${obs_date}D_${TILE}_TTI01_Q \
    -v ${MCD14DL} \
    -o $GISDBASE/../INTMED/$( basename $0 | sed 's:.sh$::g' )
done