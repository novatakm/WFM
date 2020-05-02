#!/usr/bin/env bash

usage(){
    echo $( basename $0 )
    echo "-g <GISDBASE name>"
    echo "-s <start_date (in yyyymmdd format)>"
    echo "-e <end_date (in yyyymmdd format)>"
    echo "-t <tile num. (in VxxHxx firmat)>"
    # echo "-o <out dir to store the matchup result files>"
    echo "-h help"
    exit
}

while getopts g:s:e:t:h  OPT
do
    case $OPT in
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

g.mapset map=INTMED
n_date=$( expr $( $DENV_TOOL/util/calc_datesubstr.sh $END_DATE $START_DATE ) + 1 )
obs_dates+=( $( jot $n_date 0 | xargs -I n date '+%Y%m%d' --date "n days $START_DATE") )


for obs_date in ${obs_dates[*]}
do
    $DENV_CODE/dataset/make_input_for_FRPest.sh \
    -g $GISDBASE \
    -t ${TILE} \
    -p data/FRP/PEST/ALLREGION/fit.txt \
    -d ${obs_date}D
    
    out_dir=$GISDBASE/../INTMED/$( basename $0 | sed 's:.sh$::g' )/GC1SG1_${obs_date}D_${TILE}
    mkdir -p $out_dir
    for size in 11
    do
        for e in 3 2 1
        do
            for m in $( jot 9 1 )
            do
                cp="${m}e-${e}"
                FRP_file=$out_dir/FRPEST_BKG${size}_CP${m}E${e}
                : > $FRP_file
                while read -r inp_data
                do
                    python3 $DENV_CODE/model/estimate_FRP.py \
                    -i ${inp_data} \
                    -c ${cp} >> $FRP_file
                done < $GISDBASE/../INTMED/make_input_for_FRPest/GC1SG1_${obs_date}D_${TILE}/FRPest_input_BKG$size.txt
                $DENV_CODE/dataset/make_SGLI_FRP.sh \
                -i $FRP_file -o GC1SG1_${obs_date}D_${TILE}_FRPEST_BKG${size}_CP${m}E${e}
                $DENV_CODE/dataset/make_FRPmatchup_MODISSGLI.sh \
                -i GC1SG1_${obs_date}D_${TILE}_FRPEST_BKG${size}_CP${m}E${e} \
                -o $GISDBASE/../INTMED/$( basename $0 | sed 's:.sh$::g' )
            done
        done
        cp="1e-0"
        FRP_file=$out_dir/FRPEST_BKG${size}_CP1E0
        : > $FRP_file
        while read -r inp_data
        do
            python3 $DENV_CODE/model/estimate_FRP.py \
            -i ${inp_data} \
            -c ${cp} >> $FRP_file
        done < $GISDBASE/../INTMED/make_input_for_FRPest/GC1SG1_${obs_date}D_${TILE}/FRPest_input_BKG$size.txt
        $DENV_CODE/dataset/make_SGLI_FRP.sh \
        -i $FRP_file -o GC1SG1_${obs_date}D_${TILE}_FRPEST_BKG${size}_CP1E0
        $DENV_CODE/dataset/make_FRPmatchup_MODISSGLI.sh \
        -i GC1SG1_${obs_date}D_${TILE}_FRPEST_BKG${size}_CP1E0 \
        -o $GISDBASE/../INTMED/$( basename $0 | sed 's:.sh$::g' )
    done
    
    
done