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
    # 過去N日間の観測値統計量の計算
    for ch_id in MTTI01_Q MCRSW03_Q MCRSW04_K
    do
        for nday in 16 #8
        do
            # 解析対象日の過去N日間の観測値統計量(過去N日間にわたる観測値の平均と標準偏差および晴天陸域データ数)を計算
            $DENV_CODE/feature/calc_paststats.sh \
            -i GC1SG1_${obs_date}D_${TILE}_${ch_id} \
            -n $nday \
            -c 3.0
    
        done
    done
    
    #　各チャンネル(SW03, SW04, TI01)における過去N日間の晴天画素の観測値平均(x)と解析当日の観測値(y)との間の回帰直線(y = a + b*x)のフィッティング
    # および,火災検知特徴量として,各チャンネルにおける回帰残差の算出とその画像化
    for ch_id in MCRSW03_Q MTTI01_Q MCRSW04_K
    do
        for nday in 16 #8
        do
            for subarea_size in 100 200
            do
                declare -a input_rasts=()
                input_rasts=( GC1SG1_${obs_date}D_${TILE}_${ch_id} )
                input_rasts+=( GC1SG1_${obs_date}D_${TILE}_${ch_id}_PASTMN${nday}_CL30 )
                res=$( echo $ch_id | awk 'BEGIN{FS="_"}{print $2}')
                
                $DENV_CODE/feature/calc_norm_residual.sh \
                -i $( echo ${input_rasts[*]} | sed 's: :,:g') \
                -o GC1SG1_${obs_date}D_${TILE}_${ch_id}_PASTMN${nday}_CL30_SUBAREA${subarea_size}_NORMRESID \
                -f ${GISDBASE}/../INTMED/$( basename $0 | sed 's:.sh$::g') \
                -s SUBAREA${subarea_size} -p GC1SG1_${obs_date}D_${TILE}_PATH_${res}
                
            done
            
        done
    done
    
done