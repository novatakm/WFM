#!/usr/bin/env bash

usage() {
    echo $(basename $0)
    echo "-r <rasters to be used to composite(rsw04,rsw03,rvn11,ti01 order)>"
    echo "-v <MCD14DL_vector>"
    echo "-o <name of the out dir. to which SGLI datasets are dumped>"
    echo "-h help"
    exit 0
}

FN=$$

while getopts r:v:o:h OPT
do
    case $OPT in
        r)
            RAST_NAMES=$OPTARG
        ;;
        v)
            MCD14DL=$OPTARG
        ;;
        o)
            OUT_DIR=$OPTARG
        ;;
        h)
            usage
        ;;
        \?)
            usage
        ;;
    esac
done

rast=( $( echo $RAST_NAMES | sed 's:,: :g' ) )
if [ "${rast[0]}" = "" -o "${rast[1]}" = "" -o "${rast[2]}" = "" -o "${rast[3]}" = "" ]; then
    exit 0
fi

SGLI_data_id=$( echo ${rast[0]} | awk 'BEGIN{FS="_"}{print $1"_"$2"_"$3}' )
obs_date=$( echo ${rast[0]} | awk 'BEGIN{FS="_"}{print $2}' | cut -c 1-8 )
daynight=$( echo ${rast[0]} | awk 'BEGIN{FS="_"}{print $2}' | cut -c 9 )
out_dir=$OUT_DIR/$( basename $0 | sed 's:.sh$::g' )/${SGLI_data_id}/
mkdir -p $out_dir
g.region rast=${rast[1]}
r.composite r=${rast[0]} g=${rast[1]} b=${rast[2]} out=SG_4311_$$ --o
r.out.gdal in=SG_4311_$$ out=$out_dir/SG_4311.tif format="GTiff" createopt="PROFILE=GeoTIFF" --o
r.out.gdal in=${rast[3]} out=$out_dir/TI01.tif format="GTiff" createopt="PROFILE=GeoTIFF" --o

obs_date_altform=$( date '+%Y-%m-%d' --date "$obs_date" )
v.extract in=${MCD14DL} out=mcd14dl_1day where="ACQ_DATE == '${obs_date_altform}' AND DAYNIGHT == '${daynight}'" --o
v.out.ogr in=mcd14dl_1day type=point out=$out_dir format="ESRI_Shapefile" --o
#tmpファイルの後始末
g.remove -f rast name=SG_4311_$$
g.remove -f vect name=mcd14dl_1day