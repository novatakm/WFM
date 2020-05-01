#!/usr/bin/env bash

usage() {
    echo $(basename $0)
    echo "-i <residual rasters (in sw03,sw04,ti01 format)>"
    echo "-o <output anomarousness(MH distance) raster>"
    echo "-s <subarea vector>"
    echo "-p <path_id vector>"
    echo "-h help"
    exit 0
}

FN=$$

while getopts i:o:s:p:h OPT
do
    case $OPT in
        i)
            RAST_NAMES=$OPTARG
        ;;
        o)
            ANOMAL=$OPTARG
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
rast_0_id=$( echo ${rast[0]} | awk 'BEGIN{FS="_"}{print $4}' )
rast_1_id=$( echo ${rast[1]} | awk 'BEGIN{FS="_"}{print $4$6$7}' )

# もし，指定したラスタがなければ，処理しない
if [ "$( g.list rast p=${rast[0]} )" = "" -o "$( g.list rast p=${rast[1]} )" = "" -o "$( g.list rast p=${rast[2]} )" = "" ]; then
    exit 0
fi

g.region rast=${rast[0]}
eval $( v.info -gt ${SUBAREA} )
path_ids=( $( r.category ${PATH_ID} ) )
obs_date=$( echo ${rast[0]} | awk 'BEGIN{FS="_"}{print $2}' )
declare -a anomals=()
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
        g.remove -f rast name=mask_path
        cov=( $( r.covar map=$RAST_NAMES --q 2> /dev/null | sed 's: $::g' | tail -n 3 ) )
        if [ "${cov[*]}" != "" ]; then
            inv_cov=( $( python3 $DENV_CODE/model/calc_invcovar.py --cov_list $( echo ${cov[*]} ) --dim 3 ) )
            eval $(r.univar -g map=${rast[0]}); m0=$mean
            eval $(r.univar -g map=${rast[1]}); m1=$mean
            eval $(r.univar -g map=${rast[2]}); m2=$mean
            
            # echo ${inv_cov[0]} ${inv_cov[1]} ${inv_cov[2]}
            # echo ${inv_cov[3]} ${inv_cov[4]} ${inv_cov[5]}
            # echo ${inv_cov[6]} ${inv_cov[7]} ${inv_cov[8]}
            
            r.mapcalc "uS0 = (${rast[0]}-$m0)*${inv_cov[0]} + (${rast[1]}-$m1)*${inv_cov[3]} + (${rast[2]}-$m2)*${inv_cov[6]}"
            r.mapcalc "uS1 = (${rast[0]}-$m0)*${inv_cov[1]} + (${rast[1]}-$m1)*${inv_cov[4]} + (${rast[2]}-$m2)*${inv_cov[7]}"
            r.mapcalc "uS2 = (${rast[0]}-$m0)*${inv_cov[2]} + (${rast[1]}-$m1)*${inv_cov[5]} + (${rast[2]}-$m2)*${inv_cov[8]}"
            r.mapcalc "uSu0 = uS0*(${rast[0]}-$m0)"
            r.mapcalc "uSu1 = uS1*(${rast[1]}-$m1)"
            r.mapcalc "uSu2 = uS2*(${rast[2]}-$m2)"
            r.mapcalc "anomal_${subarea_id}_${path_id} = uSu0 + uSu1 +uSu2"
            if [ "$( g.list rast p="anomal_${subarea_id}_${path_id}" )" = "anomal_${subarea_id}_${path_id}" ]; then
                anomals+=( anomal_${subarea_id}_${path_id} )
            fi
        fi
        r.mask -r
    done
done

echo "Now patching ${obs_date}"
g.region rast=${rast[0]}
r.patch inp=$( echo ${anomals[*]} | sed 's: :,:g') out=$ANOMAL --o
#r.colors -g map=$ANOMAL col=bgyr
g.remove -f rast name=$( echo ${anomals[*]} | sed 's: :,:g')
g.remove -f rast p="uS*"