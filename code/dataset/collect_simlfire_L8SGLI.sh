#!/usr/bin/env bash

usage(){
    echo $( basename $0 )
    echo "-l <path_to_dir which contains L8 tar.gz files>"
    echo "-g <GISDBASE name>"
    echo "-d <obs_date (in yyyymmdd format)>"
    echo "-t <tile num. (in VxxHxx firmat)>"
    echo "-a <acceptable obs. time gap (hr)>"
    echo "-s <name of the siml.obs.status summary file>"
    echo "-f <name of the siml.fire.status summary file>"
    echo "-h help"
    exit
}

while getopts l:g:d:t:a:s:f:h  OPT
do
    case $OPT in
        l)
            L8_DATA_DIR=$OPTARG
        ;;
        g)
            GISDBASE=$OPTARG
        ;;
        d)
            L8_OBS_DATE=$OPTARG
        ;;
        t)
            TILE=$OPTARG
        ;;
        a)
            ACCEPTABLE_TGAP=$OPTARG
        ;;
        s)
            SIMLOBS_STATUS_SUMMARY=$OPTARG
            mkdir -p $( dirname $SIMLOBS_STATUS_SUMMARY )
            touch $SIMLOBS_STATUS_SUMMARY
        ;;
        f)
            SIMLFIRE_STATUS_SUMMARY=$OPTARG
            mkdir -p $( dirname $SIMLFIRE_STATUS_SUMMARY )
            touch $SIMLFIRE_STATUS_SUMMARY
        ;;
        h)
            usage
        ;;
    esac
done

VV=$( echo $TILE | cut -c2-3 )
HH=$( echo $TILE | cut -c5-6 )

function naming_conv_L8(){
    local L8_prod_id=$1
    
    LXSS=$( echo $L8_prod_id | awk 'BEGIN{FS="_"}{print $1}' )
    LLLL=$( echo $L8_prod_id | awk 'BEGIN{FS="_"}{print $2}' )
    P=$( echo $L8_prod_id | awk 'BEGIN{FS="_"}{print $3}' | cut -c 1-3 )
    R=$( echo $L8_prod_id | awk 'BEGIN{FS="_"}{print $3}' | cut -c 4-6 )
    YYYYMMDD=$( echo $L8_prod_id | awk 'BEGIN{FS="_"}{print $4}' )
    yyyymmdd=$( echo $L8_prod_id | awk 'BEGIN{FS="_"}{print $5}' )
    CC=$( echo $L8_prod_id | awk 'BEGIN{FS="_"}{print $6}' )
    TX=$( echo $L8_prod_id | awk 'BEGIN{FS="_"}{print $7}' )
    
    echo ${LXSS}_${YYYYMMDD}_P${P}R${R}_${TX}
    
}

function calc_obstime_L8(){
    local L8_tmp_dir=$1
    local L8_data_id=$2
    local bn=$3
    
    #DN raster
    local dn=${L8_data_id}_B${bn}
    #metadata
    local mtl=`ls ${L8_tmp_dir}/*_MTL.txt`
    
    # obstime raster
    local obt=${L8_data_id}_OBT
    
    # get obstime
    local iso8061=`cat ${mtl} | grep SCENE_CENTER_TIME | awk '{print $3}' | sed 's/["|Z]//g'`
    local time=`echo ${iso8061} | awk 'BEGIN{FS=":"}{printf("%f", $1+$2/60+$3/3600)}'`
    g.region rast=${dn}
    r.mapcalc "${obt} = if(isnull(${dn}), null(), ${time})"
    echo $time
}

function list_simlSGLI(){
    local L8_obs_date=$1
    local L8_obs_time=$2
    local acceptable_tgap=$3
    
    local simltime_range=()
    simltime_range+=( $(echo "$L8_obs_time - $acceptable_tgap" | bc -l) )
    simltime_range+=( $(echo "$L8_obs_time + $acceptable_tgap" | bc -l) )
    
    local siml_status=$( echo ${simltime_range[*]} | awk '{if($1 < 0){print "-1"}else if($2 > 24){print "+1"}else{print "0"}}' )
    
    local simlSGLI_list=()
    case $siml_status in
        0)
            simlSGLI_list+=( $(g.list rast p="GC1SG1_${L8_obs_date}*_OBT_Q" | sed 's/_OBT_Q/,0/g') )
        ;;
        +1 )
            simlSGLI_list+=( $(g.list rast p="GC1SG1_${L8_obs_date}*_OBT_Q" | sed 's/_OBT_Q/,0/g') )
            simlSGLI_list+=( $(g.list rast p="GC1SG1_$(date '+%Y%m%d' --date "${siml_status} days ${L8_obs_date}")*_OBT_Q" | sed 's/_OBT_Q/,24/g') )
        ;;
        -1 )
            simlSGLI_list+=( $(g.list rast p="GC1SG1_${L8_obs_date}*_OBT_Q" | sed 's/_OBT_Q/,0/g') )
            simlSGLI_list+=( $(g.list rast p="GC1SG1_$(date '+%Y%m%d' --date "${siml_status} days ${L8_obs_date}")*_OBT_Q" | sed 's/_OBT_Q/,-24/g') )
        ;;
    esac
    
    echo ${simlSGLI_list[*]}
    
}

function eval_L8SGLI_tgap(){
    local L8_data_id=$1
    local SGLI_data_id=$( echo $2 | awk 'BEGIN{FS=","}{print $1}')
    local SGLI_obs_time_offset=$( echo $2 | awk 'BEGIN{FS=","}{print $2}')
    local acceptable_tgap=$3
    
    local L8_obt=${L8_data_id}_OBT
    local SGLI_obt=${SGLI_data_id}_OBT_Q
    local L8SGLI_obtgap=${SGLI_data_id}_${L8_data_id}_OBTGAP
    
    g.region rast=${L8_obt}
    r.mapcalc "$L8SGLI_obtgap = if(abs($L8_obt - ($SGLI_obt + ${SGLI_obs_time_offset})) > ${acceptable_tgap}, null(), $L8_obt - ($SGLI_obt + ${SGLI_obs_time_offset}))"
    eval $( r.info -r $L8SGLI_obtgap )
    max=$( echo $max | tr -d "-" | tr -d "+")
    min=$( echo $min | tr -d "-" | tr -d "+")
    if [ "$min" = "nan" -o "$max" = "nan" ]; then
        g.remove -f rast name=$L8SGLI_obtgap
        echo "0"
    else
        echo "1"
    fi
    
}

function get_L8_prod(){
    local L8_prod_id=$1
    local iter=0

    if [ ! -f ${L8_DATA_DIR}/${L8_prod_id}.tar.gz ]; then
        landsatxplore download -u $DENV_L8EXPLR_USER_NAME -p $DENV_L8EXPLR_PASS -o $L8_DATA_DIR $L8_prod_id
    fi
    while true
    do
        tar -xzf ${L8_DATA_DIR}/${L8_prod_id}.tar.gz --directory=$TMP_DIR
        status=$?
        if [ $status -eq 0 ]; then
            break
        else
            landsatxplore download -u $DENV_L8EXPLR_USER_NAME -p $DENV_L8EXPLR_PASS -o $L8_DATA_DIR $L8_prod_id
        fi
    done
}

function main(){
    
    bbox_coords=$( $DENV_TOOL/util/query_sinusoidal_bboxcoords.sh -t $TILE )
    L8_prod_ids=( $(landsatxplore search -u $DENV_L8EXPLR_USER_NAME -p $DENV_L8EXPLR_PASS -d LANDSAT_8_C1 -b $bbox_coords -s $L8_OBS_DATE -e $L8_OBS_DATE -o product_id) )

    for L8_prod_id in ${L8_prod_ids[*]}
    do
        g.mapset map=PERMANENT
        
        # L8 productのダウンロードと展開
        TMP_DIR=/tmp/$L8_prod_id; mkdir -p $TMP_DIR
        get_L8_prod $L8_prod_id

        # L8観測時刻の取得と観測時刻ラスタデータの作成
        L8_data_id=$( naming_conv_L8 $L8_prod_id )
        $DENV_TOOL/L8/import_L8.sh -i $TMP_DIR -o $L8_data_id -b "7"
        L8_obs_time=$( calc_obstime_L8 $TMP_DIR $L8_data_id "7" )
        
        # L8と同期観測している可能性のあるSGLIデータをリストアップ
        simlSGLI_list=$( list_simlSGLI $L8_OBS_DATE $L8_obs_time $ACCEPTABLE_TGAP )

        # L8とSGLIの同期観測のチェック
        g.mapset map=INTMED
        ttl_simldset=0
        for simlSGLI_id in ${simlSGLI_list}
        do
            # そもそも同期していないことが予め判っているデータセットは処理しない
            if [ "$( cat $SIMLOBS_STATUS_SUMMARY | awk '/$L8_data_id $simlSGLI_id/{print $4}' )" = "0" ]; then
                echo $L8_data_id $simlSGLI_id "skipped."
                continue
            fi

            # L8とSGLIが同期観測(許容する時間ズレ以内で双方が観測)しているかのチェック
            is_simldset=$( eval_L8SGLI_tgap ${L8_data_id} $simlSGLI_id $ACCEPTABLE_TGAP )
            # 双方の同期観測状況をファイルに記述
            # フォーマット
            #   L8_product_id L8_data_id SGLI_data_id,time_offset 同期観測状況(0:同期せず 1:同期している)
            echo "$L8_prod_id $L8_data_id $simlSGLI_id $is_simldset" >> $SIMLOBS_STATUS_SUMMARY
            cat $SIMLOBS_STATUS_SUMMARY | sort | uniq > $TMP_DIR/simlobs_status_summary.txt; mv $TMP_DIR/simlobs_status_summary.txt $SIMLOBS_STATUS_SUMMARY

            ttl_simldset=$(( ttl_simldset + is_simldset ))
        done
        # 同期観測していない場合,当該L8データは消去
        if [ $ttl_simldset -eq 0 ]; then
            for map in INTMED PERMANENT
            do
                g.mapset map=$map
                g.remove -f rast p=${L8_data_id}_*
            done
            rm -rf $TMP_DIR/
            rm ${L8_DATA_DIR}/${L8_prod_id}.tar.gz
            continue
        fi

        #
        # SGLIデータと同期観測しているL8検知画素の抽出
        #
        # L8火災検知に必要なデータをGRASSシステムへインポート
        g.mapset map=PERMANENT
        $DENV_TOOL/L8/import_L8.sh -i $TMP_DIR -o $L8_data_id -b "1 2 3 4 5 6 QA"
        # L8火災検知アルゴリズムの実行
        g.mapset map=INTMED
        $DENV_TOOL/L8/L8_wfd_day.sh $L8_data_id $TMP_DIR
        
        # L8データと同期観測している可能性のあるSGLIデータセットのリストアップ
        simlSGLI_list=$( list_simlSGLI $L8_OBS_DATE $L8_obs_time $ACCEPTABLE_TGAP )
        
        # 同期観測チェック処理をL8検知画素のみに制約
        r.mask rast=${L8_data_id}_DET maskcat="3 2 1"
        ttl_simldset=0
        for simlSGLI_id in ${simlSGLI_list}
        do
            # そもそも同期していないデータセットは処理しない
            if [ "$( cat $SIMLOBS_STATUS_SUMMARY | awk '/$L8_data_id $simlSGLI_id/{print $4}' )" = "0" ]; then
                echo $L8_data_id $simlSGLI_id "skipped."
                continue
            fi
            
            # L8検知画素とSGLI有効画素が同期観測しているかのチェック
            is_simldset=$( eval_L8SGLI_tgap ${L8_data_id} $simlSGLI_id $ACCEPTABLE_TGAP )
            # L8検知画素の同期観測状況をファイルに記述
            # フォーマット
            #   L8_product_id L8_data_id SGLI_data_id,time_offset L8検知画素の同期観測状況(0:同期せず 1:同期している)
            echo "$L8_prod_id $L8_data_id $simlSGLI_id $is_simldset" >> $SIMLFIRE_STATUS_SUMMARY
            cat $SIMLFIRE_STATUS_SUMMARY | sort | uniq > $TMP_DIR/simlfire_status_summary.txt; mv $TMP_DIR/simlfire_status_summary.txt $SIMLFIRE_STATUS_SUMMARY

            ttl_simldset=$(( ttl_simldset + is_simldset ))
        done
        # 同期観測チェック処理の制約の解除
        r.mask -r
        
        # L8検知画素がSGLIと同期観測していない場合,当該L8データは消去
        if [ $ttl_simldset -eq 0 ]; then
            for map in INTMED PERMANENT
            do
                g.mapset map=$map
                g.remove -f rast p=${L8_data_id}_*
            done
            rm -rf $TMP_DIR/
            rm ${L8_DATA_DIR}/${L8_prod_id}.tar.gz
            continue
        fi

        rm -rf $TMP_DIR/
    done
    
}

main