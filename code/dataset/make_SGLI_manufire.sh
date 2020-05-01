#!/usr/bin/env bash

usage() {
    echo $(basename $0)
    echo "-i <dirname in which manual-inspected-SGLI reffire shpfiles are contained>"
    echo "-o <name of SGLI reference fire rasters. (250m,1km order)>"
    echo "-d <obs_date in YYYYMMDD[A|D] format>"
    exit 0
}

FN=$$

while getopts i:d:o:h OPT
do
    case $OPT in
        i)
            REFFIRE_DIR=$OPTARG
        ;;
        d)
            OBS_DATE=$OPTARG
        ;;
        o)
            SGLI_REFFIRES=$OPTARG
        ;;
        h)
            usage
        ;;
        \?)
            usage
        ;;
    esac
done

SGLI_reffire_q=$( echo $SGLI_REFFIRES | awk 'BEGIN{FS=","}{print $1}')
SGLI_reffire_k=$( echo $SGLI_REFFIRES | awk 'BEGIN{FS=","}{print $2}')
obs_date=$( echo $OBS_DATE | cut -c 1-8 )
daynight=$( echo $OBS_DATE | cut -c 9)

reffire_dir=$( ls $REFFIRE_DIR/ | grep ${OBS_DATE} )
merge_shp=$REFFIRE_DIR/$reffire_dir/SGLIREFFIRE.shp
i=0
for SGLI_reffire_shp in $( ls $REFFIRE_DIR/$reffire_dir/SGLIREFFIRE_*.shp )
do
    if [ $i -eq 0 ]; then
        ogr2ogr -f 'ESRI Shapefile' -overwrite $merge_shp $SGLI_reffire_shp
    else
        ogr2ogr -f 'ESRI Shapefile' -append $merge_shp $SGLI_reffire_shp
    fi
    i=$((i+1))
done

SGLI_data_id=${reffire_dir}
g.region -d
v.in.ogr in=$merge_shp out=SGLIREFFIRE snap=1e-12 --o
g.region rast=${SGLI_data_id}_RSW03_Q
v.to.rast in=SGLIREFFIRE out=${SGLI_reffire_q} use=attr attribute_column='is_fire' --o
g.remove -f vect name=SGLIREFFIRE