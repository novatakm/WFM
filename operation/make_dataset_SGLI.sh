#!/usr/bin/env bash

usage(){
    echo $( basename $0 )
    echo "-l <path_to_dir which contains SGLI LTOAQ h5 files>"
    echo "-c <path_to_dir which contains SGLI CLFGQ h5 files>"
    echo "-g <GISDBASE name>"
    echo "-t <tile num. (in VxxHxx format)>"
    echo "-s <start_date (in yyyymmdd format)>"
    echo "-e <end_date (in yyyymmdd format)>"
    echo "-h help"
    exit
}

while getopts l:c:g:t:s:e:h  OPT
do
    case $OPT in
        l)
            LTOAQ_DIR=$OPTARG
        ;;
        c)
            CLFGQ_DIR=$OPTARG
        ;;
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

n_date=$( expr $( $DENV_TOOL/util/calc_datesubstr.sh $END_DATE $START_DATE ) + 1 )
obs_dates+=( $( jot $n_date 0 | xargs -I n date '+%Y%m%d' --date "n days $START_DATE") )

for obs_date in ${obs_dates[*]}
do
    
    g.mapset map=PERMANENT loc=LL dbase=$GISDBASE
    
    ltoaq_h5=$( ls $LTOAQ_DIR/* | grep ${obs_date}D )
    clfgq_h5=$( ls $CLFGQ_DIR/* | grep ${obs_date}D )
    
    $DENV_TOOL/SGLI/LTOAQREADIN.sh $ltoaq_h5 $GISDBASE "VN11 SW01 SW03 SW04 TI01"
    # $DENV_TOOL/SGLI/LTOAQREADIN.sh $ltoaq_h5 $GISDBASE "VN11 SW03 SW04 TI01"
    $DENV_TOOL/SGLI/CLFGQREADIN.sh $clfgq_h5 $GISDBASE
    
    
done

