#!/usr/bin/env bash

usage() {
    echo $(basename $0)
    echo "-i <resid_sw03,resid_sw04,resid_ti01,md,az,zn,azr,znr>"
    echo "-r <SGLI reffire raster>"
    echo "-o <out_dir>"
    echo "-f <out_file_name>"
    echo "-s <subarea vector name>"
    # echo "-p <path_id raster>"
    exit 0
}

tmpfn=$$

while getopts i:o:f:r:s:h OPT
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
        r)
            SGLI_REFFIRE=$OPTARG
        ;;
        s)
            SUBAREA=$OPTARG
        ;;
        # p)
        #     PATH_ID=$OPTARG
        # ;;
        h)
            usage
        ;;
        \?)
            usage
        ;;
    esac
done

rast=( $(echo $RAST_NAMES | sed 's:,: :g') )
#rast_ids=( RSDSW03 RSDSW04 RSDT01 MD AZ180 AZ360 ZN MOD14CONF MOD14OBT )

# もし，指定したラスタがなければ，処理しない
# if [ "$( g.list rast p=${rast[0]} )" = "" -o "$( g.list rast p=${rast[1]} )" = "" -o "$( g.list rast p=${rast[2]} )" = "" -o "$( g.list rast p=${rast[3]} )" = "" -o "$( g.list rast p=${rast[4]} )" = "" -o "$( g.list rast p=${rast[5]} )" = "" -o "$( g.list rast p=${rast[6]} )" = "" -o "$( g.list rast p=${rast[7]} )" = "" -o "$( g.list rast p=${rast[8]} )" = ""  ]; then
#     exit 0
# fi

SGLI_data_id=$( echo ${rast[0]} | awk 'BEGIN{FS="_"}{print $1"_"$2"_"$3}')
if [ "$( g.list rast p=${SGLI_REFFIRE} )" = "${SGLI_REFFIRE}" ]; then
    obs_date=$( echo ${rast[0]} | awk 'BEGIN{FS="_"}{print $2}' )
    out_dir=$OUT_DIR/$( basename $0 | sed 's:.sh$::g' )/${SGLI_data_id}/${SUBAREA}
    mkdir -p $out_dir
    g.region rast=${rast[0]}
    r.mask rast=${SGLI_REFFIRE} maskcat=1
    #g.region zoom=MASK
    
    feature_anoms_data=$out_dir/$OUT_FILE
    r.stats -1n inp=$( echo ${rast[*]} | sed 's: :,:g') > $feature_anoms_data
    r.mask -r
fi