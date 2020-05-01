#!/usr/bin/env bash

usage() {
    echo $(basename $0)
    echo "-i <dirname in which L8 rawfire data is contained>"
    echo "-o <name of L8 reference fire rasters. (250m,1km order)>"
    echo "-d <obs_date in YYYYMMDD[A|D] format>"
    exit 0
}

FN=$$

while getopts i:d:o:h OPT
do
    case $OPT in
        i)
            RAWFIRE_DIR=$OPTARG
        ;;
        d)
            OBS_DATE=$OPTARG
        ;;
        o)
            L8_REFFIRES=$OPTARG
        ;;
        h)
            usage
        ;;
        \?)
            usage
        ;;
    esac
done

declare -a reffires_q=()
declare -a reffires_k=()
for rawfire_dir in $( ls $RAWFIRE_DIR/ | grep GC1SG1_${OBS_DATE} )
do
    if [ -f $RAWFIRE_DIR/$rawfire_dir/L8REFFIRE.shp ]; then
        L8_data_id=$( echo $rawfire_dir | awk 'BEGIN{FS="_"}{print $4"_"$5"_"$6"_"$7}' )
        reffire_shp=$RAWFIRE_DIR/$rawfire_dir/L8REFFIRE.shp
        reffire=$( echo $rawfire_dir | sed 's:RAWFIRE:L8REFFIRE:g')
        
        g.region rast=${L8_data_id}_PR7
        v.in.ogr in=${reffire_shp} out=${reffire} where='is_fire > 0' --o
        v.to.rast in=${reffire} out=${reffire} use=attr attribute_column="is_fire" --o
        r.mapcalc "$reffire = if(isnull($reffire) && !isnull(${L8_data_id}_PR7), int(0), $reffire)"
        cat <<EOF | r.colors map=${reffire} rules=-
0 green
1 red
2 orange
3 grey
4 yellow
5 blue
EOF
        
        SGLI_data_id=$( g.list rast p="GC1SG1_${OBS_DATE}_*_OBT_Q" | cat | awk 'BEGIN{FS="_"}{print $1"_"$2"_"$3}' )
        reffire_q=${reffire}_Q
        reffire_k=${reffire}_K
        
        g.region rast=${SGLI_data_id}_RSW03_Q
        g.region zoom=${reffire}
        r.resamp.stats in=${reffire} out=${reffire_q} method="maximum" --o
        reffires_q+=( ${reffire_q} )
        
        g.region rast=${SGLI_data_id}_RSW04_K
        g.region zoom=${reffire}
        r.resamp.stats in=${reffire} out=${reffire_k} method="maximum" --o
        reffires_k+=( ${reffire_k} )
    fi
done

SGLI_data_id=$( g.list rast p="GC1SG1_${OBS_DATE}_*_OBT_Q" | cat | awk 'BEGIN{FS="_"}{print $1"_"$2"_"$3}' )
patched_reffire_q=$( echo $L8_REFFIRES | awk 'BEGIN{FS=","}{print $1}' )
patched_reffire_k=$( echo $L8_REFFIRES | awk 'BEGIN{FS=","}{print $2}' )

if [ $( echo ${reffires_q[*]} | awk '{print NF}' ) -ge 2 ]; then
    g.region rast=${SGLI_data_id}_RSW03_Q
    r.patch inp=$( echo ${reffires_q[*]} | sed 's: :,:g' ) out=${patched_reffire_q} --o
    r.null map=${patched_reffire_q} null=0
    r.mapcalc "${patched_reffire_q} = if(isnull(${SGLI_data_id}_MCRSW03_Q), null(), ${patched_reffire_q})"
    cat <<EOF | r.colors map=${patched_reffire_q} rules=-
0 green
1 red
2 orange
3 grey
4 yellow
5 blue
EOF
fi
if [ $( echo ${reffires_q[*]} | awk '{print NF}' ) -eq 1 ]; then
    g.region rast=${SGLI_data_id}_RSW03_Q
    #g.copy rast=${reffires_q[*]},${patched_reffire_q} --o
    r.mapcalc "${patched_reffire_q} = ${reffires_q[*]}"
    r.null map=${patched_reffire_q} null=0
    r.mapcalc "${patched_reffire_q} = if(isnull(${SGLI_data_id}_MCRSW03_Q), null(), ${patched_reffire_q})"
    cat <<EOF | r.colors map=${patched_reffire_q} rules=-
0 green
1 red
2 orange
3 grey
4 yellow
5 blue
EOF
fi

if [ $( echo ${reffires_k[*]} | awk '{print NF}' ) -ge 2 ]; then
    
    g.region rast=${SGLI_data_id}_RSW04_K
    r.patch inp=$( echo ${reffires_k[*]} | sed 's: :,:g' ) out=${patched_reffire_k} --o
    r.null map=${patched_reffire_k} null=0
    r.mapcalc "${patched_reffire_k} = if(isnull(${SGLI_data_id}_MCRSW04_K), null(), ${patched_reffire_k})"
    cat <<EOF | r.colors map=${patched_reffire_k} rules=-
0 green
1 red
2 orange
3 grey
4 yellow
5 blue
EOF
fi
if [ $( echo ${reffires_k[*]} | awk '{print NF}' ) -eq 1 ]; then
    g.region rast=${SGLI_data_id}_RSW04_K
    #g.copy rast=${reffires_k[*]},${patched_reffire_k} --o
    r.mapcalc "${patched_reffire_k} = ${reffires_k[*]}"
    r.null map=${patched_reffire_k} null=0
    r.mapcalc "${patched_reffire_k} = if(isnull(${SGLI_data_id}_MCRSW04_K), null(), ${patched_reffire_k})"
    cat <<EOF | r.colors map=${patched_reffire_k} rules=-
0 green
1 red
2 orange
3 grey
4 yellow
5 blue
EOF
fi