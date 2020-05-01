#!/usr/bin/env bash

usage(){
    echo $( basename $0 )
    echo "-m <path_to_dir to which MODIS products are stored (specify dirs in MOD14_dir,MOD03_dir format)>"
    echo "-d DAYNIGHT (in Day:D, Night:A format)"
    echo "-g <GISDBASE name>"
    echo "-s <start_date (in yyyymmdd format)>"
    echo "-e <end_date (in yyyymmdd format)>"
    echo "-t <tile num. (in VxxHxx firmat)>"
    echo "-h help"
    exit
}

while getopts m:d:g:s:e:t:h  OPT
do
    case $OPT in
        m)
            MODIS_DATA_DIRS=$OPTARG
        ;;
        d)
            DAYNIGHT=$OPTARG
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

MOD14_dir=$( echo $MODIS_DATA_DIRS | awk 'BEGIN{FS=","}{print $1}' )
MOD03_dir=$( echo $MODIS_DATA_DIRS | awk 'BEGIN{FS=","}{print $2}' )

# temporaryファイルズ諸々
tmp_dir=/tmp/$( basename $0 | sed 's:.sh$::g' )$$; mkdir -p $tmp_dir
lat_data=$tmp_dir/lat.tif
lon_data=$tmp_dir/lon.tif

n_date=$( expr $( $DENV_TOOL/util/calc_datesubstr.sh $END_DATE $START_DATE ) + 1 )
obs_dates+=( $( jot $n_date 0 | xargs -I n date '+%Y%m%d' --date "n days $START_DATE") )

function identify_MODIS_fp_area(){
    local lon_data=$1
    local lat_data=$2
    local FP_info=$3
    local MODIS_fp_prefix=$4
    
    for scan in $( cat $FP_info | awk '{print $3}' | sort -u )
    do
        : > $tmp_dir/${MODIS_fp_prefix}_${scan}.txt
    done
    
    cat_id=0
    while read -r fp_info;
    do
        cat_id=$((cat_id+1))
        x=$( echo $fp_info | awk '{print $1}' )
        y=$( echo $fp_info | awk '{print $2}' )
        scan=$( echo $fp_info | awk '{print $3}' )
        line=$( echo $fp_info | awk '{print $4}' )
        surr_lon=()
        surr_lat=()
        for j in -1 0 1
        do
            for i in -1 0 1
            do
                surr_lon+=( $(gdallocationinfo -valonly $lon_data $((x+i)) $((y+j)) ) )
                surr_lat+=( $(gdallocationinfo -valonly $lat_data $((x+i)) $((y+j)) ) )
            done
        done
        
        case $line in
            9)
                surr_lon[6]=$( echo "2*${surr_lon[3]} - ${surr_lon[0]}" | bc -l )
                surr_lon[7]=$( echo "2*${surr_lon[4]} - ${surr_lon[1]}" | bc -l )
                surr_lon[8]=$( echo "2*${surr_lon[5]} - ${surr_lon[2]}" | bc -l )
                surr_lat[6]=$( echo "2*${surr_lat[3]} - ${surr_lat[0]}" | bc -l )
                surr_lat[7]=$( echo "2*${surr_lat[4]} - ${surr_lat[1]}" | bc -l )
                surr_lat[8]=$( echo "2*${surr_lat[5]} - ${surr_lat[2]}" | bc -l )
            ;;
            0)
                surr_lon[0]=$( echo "2*${surr_lon[3]} - ${surr_lon[6]}" | bc -l )
                surr_lon[1]=$( echo "2*${surr_lon[4]} - ${surr_lon[7]}" | bc -l )
                surr_lon[2]=$( echo "2*${surr_lon[5]} - ${surr_lon[8]}" | bc -l )
                surr_lat[0]=$( echo "2*${surr_lat[3]} - ${surr_lat[6]}" | bc -l )
                surr_lat[1]=$( echo "2*${surr_lat[4]} - ${surr_lat[7]}" | bc -l )
                surr_lat[2]=$( echo "2*${surr_lat[5]} - ${surr_lat[8]}" | bc -l )
            ;;
        esac
        
        # UL coordinates of FP
        ul_lon=$( echo ${surr_lon[0]} ${surr_lon[1]} ${surr_lon[3]} ${surr_lon[4]} | awk '{printf("%f", ($1+$2+$3+$4)/4)}' )
        ul_lat=$( echo ${surr_lat[0]} ${surr_lat[1]} ${surr_lat[3]} ${surr_lat[4]} | awk '{printf("%f", ($1+$2+$3+$4)/4)}' )
        # UR coordinates of FP
        ur_lon=$( echo ${surr_lon[1]} ${surr_lon[2]} ${surr_lon[4]} ${surr_lon[5]} | awk '{printf("%f", ($1+$2+$3+$4)/4)}' )
        ur_lat=$( echo ${surr_lat[1]} ${surr_lat[2]} ${surr_lat[4]} ${surr_lat[5]} | awk '{printf("%f", ($1+$2+$3+$4)/4)}' )
        # LL coordinates of FP
        ll_lon=$( echo ${surr_lon[3]} ${surr_lon[4]} ${surr_lon[6]} ${surr_lon[7]} | awk '{printf("%f", ($1+$2+$3+$4)/4)}' )
        ll_lat=$( echo ${surr_lat[3]} ${surr_lat[4]} ${surr_lat[6]} ${surr_lat[7]} | awk '{printf("%f", ($1+$2+$3+$4)/4)}' )
        # LR coordinates of FP
        lr_lon=$( echo ${surr_lon[4]} ${surr_lon[5]} ${surr_lon[7]} ${surr_lon[8]} | awk '{printf("%f", ($1+$2+$3+$4)/4)}' )
        lr_lat=$( echo ${surr_lat[4]} ${surr_lat[5]} ${surr_lat[7]} ${surr_lat[8]} | awk '{printf("%f", ($1+$2+$3+$4)/4)}' )
        
        cat <<EOF >> $tmp_dir/${MODIS_fp_prefix}_${scan}.txt
B 5
$ul_lon $ul_lat
$ur_lon $ur_lat
$lr_lon $lr_lat
$ll_lon $ll_lat
$ul_lon $ul_lat
C 1 1
${surr_lon[4]} ${surr_lat[4]}
1 $cat_id
EOF
    done < $FP_info
}

function add_attributes_MODIS_fp_area(){
    local FP_info=$1
    local begin_time=$2
    local end_time=$3
    local MODIS_fp_prefix=$4
    
    cat_id=0
    while read -r fp_info;
    do
        cat_id=$((cat_id+1))
        x=$( echo $fp_info | awk '{print $1}' )
        y=$( echo $fp_info | awk '{print $2}' )
        scan=$( echo $fp_info | awk '{print $3}' )
        line=$( echo $fp_info | awk '{print $4}' )
        power=$( echo $fp_info | awk '{print $5}' )
        conf=$( echo $fp_info | awk '{print $6}' )
        vza=$( echo $fp_info | awk '{print $7}' )
        obs_time=$( echo $begin_time $end_time $scan | awk '{printf("%f", $1+$3*($2-$1)/203)}' )

        v.db.update map=${MODIS_fp_prefix}_${scan} col="sample" val=$x where="cat == $cat_id"
        v.db.update map=${MODIS_fp_prefix}_${scan} col="line" val=$y where="cat == $cat_id"
        v.db.update map=${MODIS_fp_prefix}_${scan} col="power" val=$power where="cat == $cat_id"
        v.db.update map=${MODIS_fp_prefix}_${scan} col="conf" val=$conf where="cat == $cat_id"
        v.db.update map=${MODIS_fp_prefix}_${scan} col="vza" val=$vza where="cat == $cat_id"
        v.db.update map=${MODIS_fp_prefix}_${scan} col="obs_time" val=$obs_time where="cat == $cat_id"
    done < $FP_info
}

function main(){
    
    g.mapset map=PERMANENT
    g.region -d
    for obs_date in ${obs_dates[*]}
    do
        year=$( echo $obs_date | cut -c 1-4 )
        doy=$( $DENV_TOOL/util/DOY_converter.sh -d $obs_date )
        obs_times=( $( ls $MOD14_dir/ | grep A${year}${doy} | awk 'BEGIN{FS="."}{print $3}' ) )
        for obs_time in ${obs_times[*]}
        do
            mod14_prod=$( ls $MOD14_dir/MOD14.A${year}${doy}.${obs_time}.*.hdf )
            mod03_prod=$( ls $MOD03_dir/MOD03.A${year}${doy}.${obs_time}.*.hdf )
            if [ -f $mod14_prod -a -f $mod03_prod ]; then
                
                gdal_translate HDF4_SDS:UNKNOWN:"${mod03_prod}":0 $lat_data
                gdal_translate HDF4_SDS:UNKNOWN:"${mod03_prod}":1 $lon_data
                
                FP_sample=( $( hdp dumpsds -d -s -n FP_sample ${mod14_prod} ) )
                echo ${FP_sample[*]} | sed 's: :\n:g' > $tmp_dir/FP_sample.txt
                
                FP_line=( $( hdp dumpsds -d -s -n FP_line ${mod14_prod} ) )
                echo ${FP_line[*]} | sed 's: :\n:g'  > $tmp_dir/FP_line.txt
                
                cat $tmp_dir/FP_line.txt | awk '{scan=int($1/10); line=$1-10*scan; printf("%d %d\n", scan, line)}' > $tmp_dir/FP_scan.txt
                
                FP_power=( $( hdp dumpsds -d -s -n FP_power ${mod14_prod} ) )
                echo ${FP_power[*]} | sed 's: :\n:g'  > $tmp_dir/FP_power.txt
                
                FP_conf=( $( hdp dumpsds -d -s -n FP_confidence ${mod14_prod} ) )
                echo ${FP_conf[*]} | sed 's: :\n:g'  > $tmp_dir/FP_conf.txt
                
                FP_vza=( $( hdp dumpsds -d -s -n FP_ViewZenAng ${mod14_prod} ) )
                echo ${FP_vza[*]} | sed 's: :\n:g'  > $tmp_dir/FP_vza.txt
                
                eval $( gdalinfo ${mod14_prod} | grep RANGEBEGINNINGTIME )
                begin_time=$( echo $RANGEBEGINNINGTIME | awk 'BEGIN{FS=":"}{printf("%f", $1+$2/60)}' )
                eval $( gdalinfo ${mod14_prod} | grep RANGEENDINGTIME )
                end_time=$( echo $RANGEENDINGTIME | awk 'BEGIN{FS=":"}{printf("%f", $1+$2/60)}' )

                paste -d " " \
                $tmp_dir/FP_sample.txt $tmp_dir/FP_line.txt $tmp_dir/FP_scan.txt \
                $tmp_dir/FP_power.txt $tmp_dir/FP_conf.txt $tmp_dir/FP_vza.txt \
                > $tmp_dir/FP_info.txt
                
                MODIS_fp_prefix=MODIS_${obs_date}${DAYNIGHT}_${obs_time}
                
                if [ ${#FP_line[*]} -gt 0 ]; then
                    identify_MODIS_fp_area $lon_data $lat_data $tmp_dir/FP_info.txt $MODIS_fp_prefix
                    for MODIS_fp in $( ls $tmp_dir/ | grep $MODIS_fp_prefix | sed 's:.txt$::g' )
                    do
                        v.in.ascii -n \
                        in=$tmp_dir/${MODIS_fp}.txt out=$MODIS_fp format=standard --o
                        v.db.addtable map=$MODIS_fp \
                        columns="sample int, line int, power double precision, conf int, vza double precision, obs_time double precision"
                    done
                    add_attributes_MODIS_fp_area $tmp_dir/FP_info.txt $begin_time $end_time $MODIS_fp_prefix
                fi
                
            fi
        done
    done
    
    rm -rf $tmp_dir
}

main