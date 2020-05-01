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

# 小領域ベクタの作成
for size in 100 200
do
    $DENV_CODE/preprocess/make_subarea.sh \
    -i GC1SG1_${obs_dates[0]}D_${TILE}_RSW04_K \
    -s $size \
    -o SUBAREA$size
done

for obs_date in ${obs_dates[*]}
do
    # 衛星軌道パス識別ラスタの作成
    $DENV_CODE/preprocess/identify_SGLI_paths.sh \
    -i GC1SG1_${obs_date}D_${TILE}_OBT_Q \
    -o GC1SG1_${obs_date}D_${TILE}_PATH_Q \
    -O GC1SG1_${obs_date}D_${TILE}_PATH_K
    
    # 大気上端反射率の太陽天頂角補正
    for ch in RVN11_Q RSW01_K RSW03_Q RSW04_K
    do
        $DENV_CODE/preprocess/correct_SZA.sh \
        -i GC1SG1_${obs_date}D_${TILE}_${ch} \
        -o GC1SG1_${obs_date}D_${TILE}_C${ch}
    done
    
    # 雲,雪氷,水域のマスクアウト
    for ch in CRVN11_Q CRSW01_K CRSW03_Q CRSW04_K TTI01_Q
    do
        $DENV_CODE/preprocess/maskout_cloud_water.sh \
        -i GC1SG1_${obs_date}D_${TILE}_${ch} \
        -o GC1SG1_${obs_date}D_${TILE}_M${ch} \
        -t "4 80"
    done

    
done