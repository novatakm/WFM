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

while getopts g:s:e:t:a:h  OPT
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
g.mapset map=INTMED
n_date=$( expr $( $DENV_TOOL/util/calc_datesubstr.sh $END_DATE $START_DATE ) + 1 )
obs_dates+=( $( jot $n_date 0 | xargs -I n date '+%Y%m%d' --date "n days $START_DATE") )

for obs_date in ${obs_dates[*]}
do
    $DENV_CODE/dataset/make_L8_reffire.sh \
    -i $GISDBASE/../INTMED/make_dataset_for_manuinsp_L8 \
    -o GC1SG1_${obs_date}D_${TILE}_L8REFFIRE_Q,GC1SG1_${obs_date}D_${TILE}_L8REFFIRE_K \
    -d ${obs_date}D
done

for obs_date in ${obs_dates[*]}
do
    L8_reffires=( $( g.list vect p="GC1SG1_*_LC08_${obs_date}_*_L8REFFIRE" | cat ) )
    for L8_reffire in ${L8_reffires[*]}
    do
        $DENV_CODE/dataset/dump_L8_reffire_rad7.sh \
        -i ${L8_reffire} -o $GISDBASE/../INTMED/$( basename $0 | sed 's:.sh$::g' )
    done
done

for obs_date in ${obs_dates[*]}
do
    L8_reffires=( $( g.list vect p="GC1SG1_*_LC08_${obs_date}_*_L8REFFIRE" | cat ) )
    for L8_reffire in ${L8_reffires[*]}
    do
        SGLI_simldgrid=$( echo $L8_reffire | awk 'BEGIN{FS="_"}{print $4"_"$5"_"$6"_"$7}')_SGLISIMLDGRID
        $DENV_CODE/dataset/make_SGLI_simldgrid.sh \
        -i ${L8_reffire} -o ${SGLI_simldgrid} -d $GISDBASE/../INTMED/$( basename $0 | sed 's:.sh$::g' )
        
    done
done