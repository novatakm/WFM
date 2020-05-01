#!/usr/bin/env bash

usage(){
    echo $( basename $0 )
    echo "-m <path_to_dir to which MODIS products are stored (specify in MCD14DL_dir,MOD14_dir,MOD03_dir format)>"
    echo "-f <path_to_dir in which MODIS prodname listed csv file is stored (specify in MOD14_dir,MOD03_dir format)>"
    echo "-g <GISDBASE name>"
    echo "-s <start_date (in yyyymmdd format)>"
    echo "-e <end_date (in yyyymmdd format)>"
    echo "-t <tile num. (in VxxHxx firmat)>"
    echo "-h help"
    exit
}

while getopts m:f:g:s:e:t:h  OPT
do
    case $OPT in
        m)
            MODIS_DATA_DIRS=$OPTARG
        ;;
        f)
            FNAME_CSV_DIRS=$OPTARG
        ;;
        g)
            GISDBASE=$OPTARG
        ;;
        s)
            START_DATE=$OPTARG
        ;;
        e)
            END_DATE=$OPTARG
        ;;
        t)
            TILE=$OPTARG
        ;;
        h)
            usage
        ;;
    esac
done

VV=$( echo $TILE | cut -c2-3 )
HH=$( echo $TILE | cut -c5-6 )

MCD14DL_dir=$( echo $MODIS_DATA_DIRS | awk 'BEGIN{FS=","}{print $1}' )
MOD14_dir=$( echo $MODIS_DATA_DIRS | awk 'BEGIN{FS=","}{print $2}' )
MOD03_dir=$( echo $MODIS_DATA_DIRS | awk 'BEGIN{FS=","}{print $3}' )
MOD14_fname_csv_dir=$( echo $FNAME_CSV_DIRS | awk 'BEGIN{FS=","}{print $1}' )
MOD03_fname_csv_dir=$( echo $FNAME_CSV_DIRS | awk 'BEGIN{FS=","}{print $2}' )
n_date=$( expr $( $DENV_TOOL/util/calc_datesubstr.sh $END_DATE $START_DATE ) + 1 )
obs_dates+=( $( jot $n_date 0 | xargs -I n date '+%Y%m%d' --date "n days $START_DATE") )

g.mapset map=PERMANENT
$DENV_TOOL/MODIS/import_MCD14DL.sh \
-g $GISDBASE \
-i $( ls $MCD14DL_dir/*.shp ) \
-s $START_DATE \
-e $END_DATE \
-o MCD14DL_${START_DATE}_${END_DATE} \
-t $TILE

$DENV_TOOL/MODIS/get_fnamecsv_LAADSDAAC.sh \
-s $START_DATE \
-e $END_DATE \
-o $MOD14_fname_csv_dir \
-p MOD14 \
-a $DENV_LAADSDAAC_APPKEY

$DENV_TOOL/MODIS/get_fnamecsv_LAADSDAAC.sh \
-s $START_DATE \
-e $END_DATE \
-o $MOD03_fname_csv_dir \
-p MOD03 \
-a $DENV_LAADSDAAC_APPKEY

for obs_date in ${obs_dates[*]}
do
    doy=$( $DENV_TOOL/util/DOY_converter.sh -d ${obs_date} )
    
    $DENV_TOOL/MODIS/get_MODIS_prod_over_MCD14DL.sh \
    -i MCD14DL_${obs_date} \
    -f $MOD14_fname_csv_dir/${obs_date}_${doy}.csv \
    -d D \
    -o $MOD14_dir \
    -p MOD14 \
    -a $DENV_LAADSDAAC_APPKEY

    $DENV_TOOL/MODIS/get_MODIS_prod_over_MCD14DL.sh \
    -i MCD14DL_${obs_date} \
    -f $MOD03_fname_csv_dir/${obs_date}_${doy}.csv \
    -d D \
    -o $MOD03_dir \
    -p MOD03 \
    -a $DENV_LAADSDAAC_APPKEY

done