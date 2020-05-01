#!/usr/bin/env bash

usage(){
    echo $( basename $0 )
    echo "-i <SGLI FRP estimation vector>"
    echo "-h help"
    exit
}

while getopts i:o:h  OPT
do
    case $OPT in
        i)
            SGLI_FRP=$OPTARG
        ;;
        o)
            OUT_DIR=$OPTARG
        ;;
        h)
            usage
        ;;
    esac
done

g.mapset map=INTMED
g.region -d
obs_date=$( echo $SGLI_FRP | awk 'BEGIN{FS="_"}{print $2}' )
bkg=$( echo $SGLI_FRP | awk 'BEGIN{FS="_"}{print $5}' )
cp=$( echo $SGLI_FRP | awk 'BEGIN{FS="_"}{print $6}' )

for MODIS_fp in $( g.list vect p="MODIS_${obs_date}*")
do
    time_id=$( echo $MODIS_fp | awk 'BEGIN{FS="_"}{print $3}')
    scan_id=$( echo $MODIS_fp | awk 'BEGIN{FS="_"}{print $4}')
    FRP_matchup=MODSG_${obs_date}_${bkg}_${cp}_${scan_id}
    g.copy vect=${MODIS_fp},${FRP_matchup} --o

    v.vect.stats points=${SGLI_FRP} area=${FRP_matchup} method="average" \
    points_col="SGLI_obstime" count_col="SGLI_fp_count" stats_col="SGLI_obstime"
    v.vect.stats points=${SGLI_FRP} area=${FRP_matchup} method="sum" \
    points_col="isval_sw04" count_col="SGLI_fp_count" stats_col="valid_sw04_total"
    v.vect.stats points=${SGLI_FRP} area=${FRP_matchup} method="sum" \
    points_col="isval_sw03" count_col="SGLI_fp_count" stats_col="valid_sw03_total"
    v.vect.stats points=${SGLI_FRP} area=${FRP_matchup} method="sum" \
    points_col="FRP" count_col="SGLI_fp_count" stats_col="SGLI_FRP"

done

out_dir=$OUT_DIR/$( basename $0 | sed 's:.sh$::g' )
mkdir -p $out_dir
out_file=$out_dir/MODSG_${obs_date}_${bkg}_${cp}.txt
: > $out_file
itr=0
for MODSG_matchup in $( g.list vect p="MODSG_${obs_date}_${bkg}_${cp}_*" )
do
    if [ $itr -eq 0 ]; then
        v.db.select map=${MODSG_matchup} sep=space where="SGLI_fp_count > 0" col=power,conf,vza,obs_time,SGLI_fp_count,SGLI_obstime,valid_sw04_total,valid_sw03_total,SGLI_FRP >> $out_file
    else
        v.db.select -c map=${MODSG_matchup} sep=space where="SGLI_fp_count > 0" col=power,conf,vza,obs_time,SGLI_fp_count,SGLI_obstime,valid_sw04_total,valid_sw03_total,SGLI_FRP >> $out_file
    fi
    itr=$((itr+1))
done