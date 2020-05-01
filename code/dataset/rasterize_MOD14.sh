#!/usr/bin/env bash

usage(){
    echo $( basename $0 )
    echo "-g <GISDBASE name>"
    echo "-t <tile num. (in VxxHxx firmat)>"
    echo "-d <obs_date (in yyyymmdd[A|D] format)>"
    echo "-c <name of the attribute column(s) to be rasterised (separate names in \",\" default: conf,obs_time)>"
    echo "-t <tile num. (in VxxHxx firmat)>"
    echo "-h help"
    exit
}

ATTR_COLS="conf,obs_time"
while getopts g:t:d:c:h  OPT
do
    case $OPT in
        g)
            GISDBASE=$OPTARG
        ;;
        d)
            OBS_DATE_DN=$OPTARG
        ;;
        c)
            ATTR_COLS=$OPTARG
        ;;
        t)
            TILE=$OPTARG
        ;;
        h)
            usage
        ;;
    esac
done

MOD14_vects=( $( g.list vect p="MODIS_${OBS_DATE_DN}_*" ) )
if [ ${#MOD14_vects[*]} -eq 0 ]; then
    exit
fi
attr_cols=( $( echo $ATTR_COLS | sed 's:,: :g' ) )

g.region rast=GC1SG1_${OBS_DATE_DN}_${TILE}_RSW03_Q
for attr_col in ${attr_cols[*]}
do
    declare -a MOD14_rasts=()
    for MOD14_vect in ${MOD14_vects[*]}
    do
        MOD14_rast=$MOD14_vect
        v.to.rast in=$MOD14_vect out=$MOD14_rast use=attr attribute_column=$attr_col --o
        MOD14_rasts+=( $MOD14_rast )
    done
    r.patch inp=$( echo ${MOD14_rasts[*]} | sed 's: :,:g') out=MODIS_${OBS_DATE_DN}_${attr_col} --o
done
g.remove -f rast name=$( echo ${MOD14_rasts[*]} | sed 's: :,:g' )