#!/usr/bin/env bash

usage(){
    echo $( basename $0 )
    echo "-l <path_to_dir which contains L8 tar.gz files>"
    echo "-g <GISDBASE name>"
    echo "-s <start_date (in yyyymmdd format)>"
    echo "-e <end_date (in yyyymmdd format)>"
    echo "-t <tile num. (in VxxHxx firmat)>"
    echo "-a <acceptable obs. time gap (hr)>"
    echo "-h help"
    exit
}

while getopts l:g:s:e:t:a:h  OPT
do
    case $OPT in
        l)
            L8_DATA_DIR=$OPTARG
        ;;
        g)
            GISDBASE=$OPTARG
        ;;
        s)
            START_DATE=$OPTARG
        ;;
        e)
            END_DATE=$OPTARG
        ;;
        t)
            TILE=$OPTARG
        ;;
        a)
            ACCEPTABLE_TGAP=$OPTARG
        ;;
        h)
            usage
        ;;
    esac
done

VV=$( echo $TILE | cut -c2-3 )
HH=$( echo $TILE | cut -c5-6 )
#out_dir=$GISDBASE/../INTMED/$(basename $0)

n_date=$( expr $( $DENV_TOOL/util/calc_datesubstr.sh $END_DATE $START_DATE ) + 1 )
obs_dates+=( $( jot $n_date 0 | xargs -I n date '+%Y%m%d' --date "n days $START_DATE") )

for obs_date in ${obs_dates[*]}
do
    $DENV_CODE/dataset/collect_simlfire_L8SGLI.sh \
    -l $L8_DATA_DIR -g $(g.gisenv GISDBASE) \
    -d $obs_date -t $TILE -a $ACCEPTABLE_TGAP \
    -s $GISDBASE/../INTMED/$(basename $0)/etc/L8SGLI_simlobs_stats.txt \
    -f $GISDBASE/../INTMED/$(basename $0)/etc/L8SGLI_simlfire_stats.txt
done

g.mapset map=INTMED
for obs_date in ${obs_dates[*]}
do
    for L8SGLI_obtgap in $( g.list rast p="GC1SG1_${obs_date}*_LC08_*_OBTGAP" | cat )
    do
        L8SGLI_rawfire=$( echo $L8SGLI_obtgap | sed 's:OBTGAP$:RAWFIRE:g')
        shp_dir=$GISDBASE/../INTMED/$( basename $0 | sed 's:.sh$::g' )/$L8SGLI_rawfire
        mkdir -p $shp_dir
        $DENV_CODE/dataset/make_L8_rawfire.sh -i $L8SGLI_obtgap -o $L8SGLI_rawfire -s $shp_dir
    done
done