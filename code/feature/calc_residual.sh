#!/usr/bin/env bash

usage() {
    echo $(basename $0)
    echo "-i <raster(map_y),raster_pastmean(map_x)>"
    echo "-f <dir. to which the fitting parameters are dumped>"
    echo "-o <residual>"
    echo "-s <subarea vector>"
    echo "-p <path_category id raster>"
    exit 0
}

tmpfn=$$

while getopts i:f:o:s:p:h OPT
do
    case $OPT in
        i)
            RAST_NAMES=$OPTARG
        ;;
        o)
            RESIDUAL=$OPTARG
        ;;
        s)
            SUBAREA=$OPTARG
        ;;
        p)
            PATH_ID=$OPTARG
        ;;
        f)
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
rast_0_id=$( echo ${rast[0]} | awk 'BEGIN{FS="_"}{print $4}' )
rast_1_id=$( echo ${rast[1]} | awk 'BEGIN{FS="_"}{print $4$6$7}' )

# もし，指定したラスタがなければ，処理しない
if [ "$( g.list rast p=${rast[0]} )" = "" -o "$( g.list rast p=${rast[1]} )" = "" ]; then
    exit 0
fi

g.region rast=${rast[0]}
eval $( v.info -gt ${SUBAREA} )
path_ids=( $( r.category ${PATH_ID} ) )
obs_date=$( echo ${rast[0]} | awk 'BEGIN{FS="_"}{print $2}' )
out_dir=${OUT_DIR}/$( basename $0 | sed 's:.sh$::g' )/${obs_date}/${SUBAREA}
mkdir -p $out_dir
declare -a residuals=()
for subarea_id in $( jot $areas 1 )
do
    for path_id in ${path_ids[*]}
    do
        echo "Now Processing ${obs_date} ${subarea_id} ${path_id}"
        g.region rast=${rast[0]}
        r.mask vect=${SUBAREA} cat=${subarea_id}
        g.region zoom=MASK
        r.mapcalc "mask_path = if(${PATH_ID} == ${path_id}, int(1), null())"
        r.mapcalc "MASK = if(mask_path & MASK, int(1), null())"
        eval $( r.regression.line -g mapx=${rast[1]} mapy=${rast[0]} )
        if [ "$a" != "-nan" -a "$b" != "-nan" ]; then
            r.mapcalc "residual_${subarea_id}_${path_id} = if(MASK, ${rast[0]} - ($a + $b*${rast[1]}), null())"
            cat <<EOF > $out_dir/${rast_0_id}_${rast_1_id}_${subarea_id}_${path_id}.txt
a=$a
b=$b
R=$R
N=$N
EOF
            residuals+=( residual_${subarea_id}_${path_id} )
        fi
        r.mask -r
        g.remove -f rast name=mask_path
    done
done

echo "Now Patching ${obs_date}"
g.region rast=${rast[0]}
r.patch inp=$( echo ${residuals[*]} | sed 's: :,:g' ) out=$RESIDUAL --o
g.remove -f rast name=$( echo ${residuals[*]} | sed 's: :,:g' )