#!/usr/bin/env bash

usage() {
    echo $(basename $0)
    echo "-i <raster,raster_pastmean,raster_pastsd,raster_pastcnt>"
    echo "-o <out_dir>"
    echo "-s <subarea vector>"
    echo "-p <path_id raster>"
    exit 0
}

tmpfn=$$

while getopts i:o:s:p:h OPT
do
    case $OPT in
        i)
            RAST_NAMES=$OPTARG
        ;;
        o)
            OUT_DIR=$OPTARG
        ;;
        s)
            SUBAREA=$OPTARG
        ;;
        p)
            PATH_ID=$OPTARG
        ;;
        h)
            usage
        ;;
        \?)
            usage
        ;;
    esac
done

rast=( $(echo $RAST_NAMES | sed 's:,: :g') )
rast_0_id=$( echo ${rast[0]} | awk 'BEGIN{FS="_"}{print $4}' )
rast_1_id=$( echo ${rast[1]} | awk 'BEGIN{FS="_"}{print $4$6$7}' )

# もし，指定したラスタがなければ，処理しない
if [ "$( g.list rast p=${rast[0]} )" = "" -o "$( g.list rast p=${rast[1]} )" = "" -o "$( g.list rast p=${rast[2]} )" = "" -o "$( g.list rast p=${rast[3]} )" = "" ]; then
    exit 0
fi

eval $( v.info -gt ${SUBAREA} )
path_ids=( $( r.category ${PATH_ID} ) )
obs_date=$( echo ${rast[0]} | awk 'BEGIN{FS="_"}{print $2}' )
out_dir=$OUT_DIR/$( basename $0 | sed 's:.sh$::g' )/$obs_date/$SUBAREA/
mkdir -p $out_dir
for subarea_id in $( jot $areas 1 )
do
    for path_id in ${path_ids[*]}
    do
        g.region rast=${rast[0]}
        r.mask vect=${SUBAREA} cat=${subarea_id}
        g.region zoom=MASK
        r.mapcalc "mask_path = if(${PATH_ID} == ${path_id}, int(1), null())"
        r.mapcalc "mask_inlier = if(abs( (${rast[0]}-${rast[1]})/${rast[2]} ) < 3.0, int(1), null())"
        r.mapcalc "MASK = if(mask_path & mask_inlier & MASK, int(1), null())"
        
        fit_data=$out_dir/${rast_1_id}_${rast_0_id}_${subarea_id}_${path_id}.txt
        r.stats -1n inp=${rast[1]},${rast[0]} > $fit_data
        r.mask -r
        
        if [ $( cat $fit_data | wc -l) -eq 0 ]; then
            rm $fit_data
        fi
        g.remove -f rast name=mask_path,mask_inlier
    done
done
