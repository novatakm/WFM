#!/usr/bin/env bash

usage() {
    echo $(basename $0)
    echo "-i <raster,raster_pastmean>"
    echo "-f <dir name that contains fitting parameter files>"
    echo "-o <residual,norm_resudual>"
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
        f)
            FIT_PRM_DIR=$OPTARG
        ;;
        o)
            RESIDUALS=$OPTARG
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

rast=( $( echo $RAST_NAMES | sed 's:,: :g' ) )
residual=( $( echo $RESIDUALS  | sed 's:,: :g' ) )
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

declare -a residuals=()
declare -a norm_residuals=()
for subarea_id in $( jot $areas 1 )
do
    for path_id in ${path_ids[*]}
    do
        if [ -f $FIT_PRM_DIR/${rast_1_id}_${rast_0_id}_${subarea_id}_${path_id}.txt ]; then
            echo "Now Processing ${subarea_id} ${path_id}"
            g.region rast=${rast[0]}
            r.mask vect=${SUBAREA} cat=${subarea_id}
            g.region zoom=MASK
            r.mapcalc "mask_path = if(${PATH_ID} == ${path_id}, int(1), null())"
            r.mapcalc "MASK = if(mask_path & MASK, int(1), null())"
            eval $( cat $FIT_PRM_DIR/${rast_1_id}_${rast_0_id}_${subarea_id}_${path_id}.txt )
            r.mapcalc "residual_${subarea_id}_${path_id} = if(MASK, ${rast[0]} - ($a*${rast[1]}+$b), null())"
            r.mapcalc "norm_residual_${subarea_id}_${path_id} = if(MASK, (${rast[0]} - ($a*${rast[1]}+$b))/${std_e}, null())"
            r.mask -r
            g.remove -f rast name=mask_path
            residuals+=( residual_${subarea_id}_${path_id} )
            norm_residuals+=( norm_residual_${subarea_id}_${path_id} )
            g.region rast=${rast[0]}
        fi
    done
done

g.region rast=${rast[0]}
r.patch inp=$( echo ${residuals[*]} | sed 's: :,:g' ) out=${residual[0]} --o
r.patch inp=$( echo ${norm_residuals[*]} | sed 's: :,:g' ) out=${residual[1]} --o
g.remove -f rast name=$( echo ${residuals[*]} | sed 's: :,:g' )
g.remove -f rast name=$( echo ${norm_residuals[*]} | sed 's: :,:g' )