#!/usr/bin/env bash

usage(){
    echo $( basename $0 )
    echo "-g <GISDBASE name>"
    echo "-t <tile num. in VvvHhh format>"
    echo "-s <start_date (in yyyymmdd format)>"
    echo "-e <end_date (in yyyymmdd format)>"
    echo "-h help"
    exit
}

while getopts g:t:s:e:h  OPT
do
    case $OPT in
        g)
            GISDBASE=$OPTARG
        ;;
        t)
            TILE=$OPTARG
        ;;
        s)
            START_DATE=$OPTARG
        ;;
        e)
            END_DATE=$OPTARG
        ;;
        h)
            usage
        ;;
    esac
done

g.mapset map=INTMED loc=LL dbase=$GISDBASE

n_date=$( expr $( $DENV_TOOL/util/calc_datesubstr.sh $END_DATE $START_DATE ) + 1 )
obs_dates+=( $( jot $n_date 0 | xargs -I n date '+%Y%m%d' --date "n days $START_DATE") )

for obs_date in ${obs_dates[*]}
do
    for ssize in 100 200
    do
        $DENV_ROOT/verif/dump_feature_anomals_over_SGLImanufire_MOD14.sh \
        -i GC1SG1_${obs_date}D_${TILE}_MCRSW03_Q_PASTMN16_CL30_SUBAREA${ssize}_NORMRESID,GC1SG1_${obs_date}D_${TILE}_MCRSW04_K_PASTMN16_CL30_SUBAREA${ssize}_NORMRESID,GC1SG1_${obs_date}D_${TILE}_MTTI01_Q_PASTMN16_CL30_SUBAREA${ssize}_NORMRESID,GC1SG1_${obs_date}D_${TILE}_SW03SW04TI01_Q_PASTMN16_CL30_SUBAREA${ssize}_MD,GC1SG1_${obs_date}D_${TILE}_SW03SW04TI01_Q_PASTMN16_CL30_SUBAREA${ssize}_AZ180,GC1SG1_${obs_date}D_${TILE}_SW03SW04TI01_Q_PASTMN16_CL30_SUBAREA${ssize}_AZ360,GC1SG1_${obs_date}D_${TILE}_SW03SW04TI01_Q_PASTMN16_CL30_SUBAREA${ssize}_ZN,GC1SG1_${obs_date}D_${TILE}_OBT_Q,MODIS_${obs_date}D_conf,MODIS_${obs_date}D_obs_time \
        -o $GISDBASE/../INTMED/$( basename $0 | sed 's:.sh$::g' ) \
        -f RSD03_RSD04_RSD01_MD_AZ18_AZ36_ZN_SGLIOBT_MOD14CONF_MOD14OBT.txt \
        -r GC1SG1_${obs_date}D_${TILE}_SGLIREFFIRE_Q \
        -s SUBAREA${ssize}
        
    done
done