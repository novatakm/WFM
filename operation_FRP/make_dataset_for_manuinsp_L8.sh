#!/usr/bin/env bash

usage(){
    echo $( basename $0 )
    echo "-g <GISDBASE name>"
    echo "-s <start_date (in yyyymmdd format)>"
    echo "-e <end_date (in yyyymmdd format)>"
    echo "-t <tile num. (in VxxHxx firmat)>"
    echo "-h help"
    exit
}

while getopts g:s:e:t:h  OPT
do
    case $OPT in
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

g.mapset map=INTMED
for obs_date in ${obs_dates[*]}
do
    for L8SGLI_obtgap in $( g.list rast p="GC1SG1_${obs_date}*_LC08_*_OBTGAP" | cat )
    do
        #if [ "$L8SGLI_obtgap" = "GC1SG1_20191018D_V12H30_LC08_20191018_P093R083_T1_OBTGAP" ]; then
        L8SGLI_rawfire=$( echo $L8SGLI_obtgap | sed 's:OBTGAP$:RAWFIRE:g')
        shp_dir=$GISDBASE/../INTMED/$( basename $0 | sed 's:.sh$::g' )/$L8SGLI_rawfire
        mkdir -p $shp_dir
        $DENV_CODE/dataset/make_L8_rawfire.sh -i $L8SGLI_obtgap -o $L8SGLI_rawfire -s $shp_dir
        #fi
    done
done