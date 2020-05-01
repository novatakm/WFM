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
    # 観測値異常度の算出
    for nday in 16 #8
    do
        for subarea_size in 100 200
        do
            $DENV_CODE/model/calc_anoms.sh \
            -i GC1SG1_${obs_date}D_${TILE}_MCRSW03_Q_PASTMN${nday}_CL30_SUBAREA${subarea_size}_NORMRESID,GC1SG1_${obs_date}D_${TILE}_MCRSW04_K_PASTMN${nday}_CL30_SUBAREA${subarea_size}_NORMRESID,GC1SG1_${obs_date}D_${TILE}_MTTI01_Q_PASTMN${nday}_CL30_SUBAREA${subarea_size}_NORMRESID \
            -o GC1SG1_${obs_date}D_${TILE}_SW03SW04TI01_Q_PASTMN${nday}_CL30_SUBAREA${subarea_size}_MD \
            -s SUBAREA${subarea_size} \
            -p GC1SG1_${obs_date}D_${TILE}_PATH_Q

            $DENV_CODE/model/calc_polcoords360.sh \
            -i GC1SG1_${obs_date}D_${TILE}_MCRSW03_Q_PASTMN${nday}_CL30_SUBAREA${subarea_size}_NORMRESID,GC1SG1_${obs_date}D_${TILE}_MCRSW04_K_PASTMN${nday}_CL30_SUBAREA${subarea_size}_NORMRESID,GC1SG1_${obs_date}D_${TILE}_MTTI01_Q_PASTMN${nday}_CL30_SUBAREA${subarea_size}_NORMRESID \
            -o GC1SG1_${obs_date}D_${TILE}_SW03SW04TI01_Q_PASTMN${nday}_CL30_SUBAREA${subarea_size}_ZN,GC1SG1_${obs_date}D_${TILE}_SW03SW04TI01_Q_PASTMN${nday}_CL30_SUBAREA${subarea_size}_AZ360 \
            -s SUBAREA${subarea_size} \
            -p GC1SG1_${obs_date}D_${TILE}_PATH_Q

            $DENV_CODE/model/calc_polcoords180.sh \
            -i GC1SG1_${obs_date}D_${TILE}_MCRSW03_Q_PASTMN${nday}_CL30_SUBAREA${subarea_size}_NORMRESID,GC1SG1_${obs_date}D_${TILE}_MCRSW04_K_PASTMN${nday}_CL30_SUBAREA${subarea_size}_NORMRESID,GC1SG1_${obs_date}D_${TILE}_MTTI01_Q_PASTMN${nday}_CL30_SUBAREA${subarea_size}_NORMRESID \
            -o GC1SG1_${obs_date}D_${TILE}_SW03SW04TI01_Q_PASTMN${nday}_CL30_SUBAREA${subarea_size}_ZN,GC1SG1_${obs_date}D_${TILE}_SW03SW04TI01_Q_PASTMN${nday}_CL30_SUBAREA${subarea_size}_AZ180 \
            -s SUBAREA${subarea_size} \
            -p GC1SG1_${obs_date}D_${TILE}_PATH_Q
            
            # $DENV_CODE/model/calc_polcoords_radian.sh \
            # -i GC1SG1_${obs_date}D_${TILE}_MCRSW03_Q_PASTMN${nday}_CL30_SUBAREA${subarea_size}_NORMRESID,GC1SG1_${obs_date}D_${TILE}_MCRSW04_K_PASTMN${nday}_CL30_SUBAREA${subarea_size}_NORMRESID,GC1SG1_${obs_date}D_${TILE}_MTTI01_Q_PASTMN${nday}_CL30_SUBAREA${subarea_size}_NORMRESID \
            # -o GC1SG1_${obs_date}D_${TILE}_SW03SW04TI01_Q_PASTMN${nday}_CL30_SUBAREA${subarea_size}_ZNR,GC1SG1_${obs_date}D_${TILE}_SW03SW04TI01_Q_PASTMN${nday}_CL30_SUBAREA${subarea_size}_AZR \
            # -s SUBAREA${subarea_size} \
            # -p GC1SG1_${obs_date}D_${TILE}_PATH_Q
            
        done
    done
done