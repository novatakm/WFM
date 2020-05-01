#!/usr/bin/env bash

usage() {
    echo $(basename $0)
    echo "-i <residual rasters (in sw03,sw04,ti01 format)>"
    echo "-o <output angle rasters (in zenith,azimuth format)>"
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
            POLCOODS=$OPTARG
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
angls=( $( echo $POLCOODS | sed 's:,: :g' ) )

# もし，指定したラスタがなければ，処理しない
if [ "$( g.list rast p=${rast[0]} )" = "" -o "$( g.list rast p=${rast[1]} )" = "" -o "$( g.list rast p=${rast[2]} )" = "" ]; then
    exit 0
fi

g.region rast=${rast[0]}
eval $( v.info -gt ${SUBAREA} )
path_ids=( $( r.category ${PATH_ID} ) )
obs_date=$( echo ${rast[0]} | awk 'BEGIN{FS="_"}{print $2}' )

r.mapcalc "${angls[0]} = acos(${rast[2]}/sqrt(${rast[0]}^2+${rast[1]}^2+${rast[2]}^2))"
r.mapcalc "${angls[1]} = if(${rast[1]}>0, acos(${rast[0]}/sqrt(${rast[0]}^2+${rast[1]}^2)), -1*acos(${rast[0]}/sqrt(${rast[0]}^2+${rast[1]}^2)))"
