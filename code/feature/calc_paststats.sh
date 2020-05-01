#!/usr/bin/env bash

usage() {
    echo $(basename $0)
    echo "-i <raster name of the base date>"
    echo "-n <a number of the past days data to use for calculating the statistics> "
    echo "-c <a threshold value for cleansing outliers from the past data>"
    exit 0
}

tmpfn=$$

while getopts i:n:c:h OPT
do
    case $OPT in
        i)
            RAST_NAME=$OPTARG
        ;;
        n)
            NDAY=$OPTARG
        ;;
        c)
            CLN_THD=$OPTARG
        ;;
        h)
            usage
        ;;
        \?)
            usage
        ;;
    esac
done

# もし，処理対象とする日の観測データbase_rastがなければ，処理しない
base_rast=$( g.list rast p=$RAST_NAME | cat )
if [ "$base_rast" = "" ]; then
    exit 0
fi

# 処理対象日base_dateより過去NDAY日分の観測データ名を取得し，配列変数past_rastsに格納
base_date=$( echo $base_rast | awk 'BEGIN{FS="_"}{print $2}' | cut -c 1-8 )
ad=$( echo $base_rast | awk 'BEGIN{FS="_"}{print $2}' | cut -c 9 )
tile=$( echo $base_rast | awk 'BEGIN{FS="_"}{print $3}' )
ch_id=$( echo $base_rast | awk 'BEGIN{FS="_"}{print $4"_"$5}' )
declare -a past_rasts=()
for n in $( jot $NDAY 1 ); do
    past_date=$( date '+%Y%m%d' --date "-$n days $base_date" )
    past_rasts+=( $( g.list rast p="GC1SG1_${past_date}${ad}_${tile}_${ch_id}" | cat) )
done

# もし，過去NDAY日の間に一つも観測データが無ければ，処理しない
if [ "${past_rasts[*]}" = "" ]; then
    exit 0
fi

# base_dateより過去NDAY日分の有効観測値の統計量（有効データ数，平均，標準偏差）を計算
past_cnt=GC1SG1_${base_date}${ad}_${tile}_${ch_id}_PASTCNT$NDAY
past_mean=GC1SG1_${base_date}${ad}_${tile}_${ch_id}_PASTMN$NDAY
past_sd=GC1SG1_${base_date}${ad}_${tile}_${ch_id}_PASTSD$NDAY
g.region rast=$base_rast
r.series inp=$( echo ${past_rasts[*]} | sed 's: :,:g' ) method=count,average,stddev \
out=$past_cnt,$past_mean,$past_sd --o
r.colors map=$past_mean,$past_sd col=grey --o

# 過去NDAY日分のデータから外れ値（取り逃しの雲とか過去の火災とか）を除去して，統計量を再計算
declare -a cleansed_rasts=()
for past_rast in $( echo ${past_rasts[*]} )
do
    r.mapcalc "${past_rast}_CL = if($past_cnt >= 2 && abs(($past_rast - $past_mean)/$past_sd) < $CLN_THD, $past_rast, null())"
    cleansed_rasts+=( ${past_rast}_CL )
done
past_cnt_cl=GC1SG1_${base_date}${ad}_${tile}_${ch_id}_PASTCNT${NDAY}_CL$( echo $CLN_THD | tr -d '.')
past_mean_cl=GC1SG1_${base_date}${ad}_${tile}_${ch_id}_PASTMN${NDAY}_CL$( echo $CLN_THD | tr -d '.')
past_sd_cl=GC1SG1_${base_date}${ad}_${tile}_${ch_id}_PASTSD${NDAY}_CL$( echo $CLN_THD | tr -d '.')
g.region rast=$base_rast
r.series inp=$( echo ${cleansed_rasts[*]} | sed 's: :,:g' ) method=count,average,stddev \
out=$past_cnt_cl,$past_mean_cl,$past_sd_cl --o
r.colors map=$past_mean_cl,$past_sd_cl col=grey --o

# ファイルの後始末
g.remove -f rast name=$( echo ${cleansed_rasts[*]} | sed 's: :,:g' )
#g.remove -f rast name=$past_cnt,$past_mean,$past_sd
