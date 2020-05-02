#!/usr/bin/env bash

usage() {
    echo $(basename $0)
    echo "-i <resid_sw03,resid_sw04,resid_ti01,az18,az36,zn,md,SGLI_reffire,MODIS_conf>"
    echo "-o <out_dir>"
    echo "-f <out_file>"
    exit 0
}

tmpfn=$$

while getopts i:o:f:h OPT
do
    case $OPT in
        i)
            RAST_NAMES=$OPTARG
        ;;
        o)
            OUT_DIR=$OPTARG
        ;;
        f)
            OUT_FILE=$OPTARG
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
rast_ids=( RSDSW03 RSDSW04 RSDT01 MD SGF MODCONF )

# もし，指定したラスタがなければ，処理しない
# if [ "$( g.list rast p=${rast[0]} )" = "" -o "$( g.list rast p=${rast[1]} )" = "" -o "$( g.list rast p=${rast[2]} )" = "" -o "$( g.list rast p=${rast[3]} )" = "" -o "$( g.list rast p=${rast[4]} )" = "" -o "$( g.list rast p=${rast[5]} )" = "" ]; then
#     exit 0
# fi

# eval $( v.info -gt ${SUBAREA} )
# path_ids=( $( r.category ${PATH_ID} ) )
SGLI_data_id=$( echo ${rast[0]} | awk 'BEGIN{FS="_"}{print $1"_"$2"_"$3}' )
obs_date=$( echo ${rast[0]} | awk 'BEGIN{FS="_"}{print $2}' )
subarea_id=$( echo ${rast[0]} | awk 'BEGIN{FS="_"}{print $(NF-1)}' )

out_dir=$OUT_DIR/$( basename $0 | sed 's:.sh$::g' )/$SGLI_data_id/$subarea_id/
mkdir -p $out_dir

g.region rast=${rast[0]}
g.copy rast=${rast[4]},SGF_null0
g.copy rast=${rast[5]},MODIS_conf_null0
if [ "$( g.list rast p="${rast[5]}" )" = "" ]; then
    r.mapcalc "MODIS_conf_null0 = int(0)"
else
    r.null map=MODIS_conf_null0 null=0
fi
r.null map=SGF_null0 null=0
r.mapcalc "MASK = if(!isnull(${rast[0]}) && !isnull(${rast[1]}) && !isnull(${rast[2]}) && !isnull(${rast[3]}), int(1), null())"
feature_anoms_data=$out_dir/$OUT_FILE
# echo "${rast_ids[*]}" > $feature_anoms_data
: > $feature_anoms_data
# r.stats -1n inp=$( echo ${rast[*]} | sed 's: :,:g') >> $feature_anoms_data
r.stats -1n inp=${rast[0]},${rast[1]},${rast[2]},${rast[3]},SGF_null0,MODIS_conf_null0 >> $feature_anoms_data
if [ $( cat $feature_anoms_data | wc -l ) -eq 1 ]; then
    rm $feature_anoms_data
fi

r.mask -r
g.remove -f rast name=MODIS_conf_null0,SGF_null0