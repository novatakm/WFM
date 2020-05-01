#!/usr/bin/env bash

usage(){
    echo $( basename $0 )
    echo "-n <L8REFFIRE vector name>"
    echo "-b <band num.>"
    echo "-t <tile num. (in VxxHxx format)>"
    echo "-h help"
    exit
}

while getopts n:b:t:h  OPT
do
    case $OPT in
        n)
            L8REFFIRE_VECT=$OPTARG
        ;;
        b)
            BAND_NUM=$OPTARG
        ;;
        t)
            TILE=$OPTARG
        ;;
        h)
            usage
        ;;
    esac
done

obs_date=$( echo ${L8REFFIRE_VECT} | awk 'BEGIN{FS="_"}{print $5}' )
path=$( echo ${L8REFFIRE_VECT} | awk 'BEGIN{FS="_"}{print $6}' | cut -c 2-4 )
row=$( echo ${L8REFFIRE_VECT} | awk 'BEGIN{FS="_"}{print $6}' | cut -c 6-8 )
L8_tgz=$( ls /home2/L8C1/${TILE}/2019/L1/LC08_L1*_${path}${row}_${obs_date}_*.tar.gz )
if [ "$L8_tgz" = "" ]; then
    L8_tgz=$( ls /mnt/L8C1/${TILE}/2019/L1/LC08_L1*_${path}${row}_${obs_date}_*.tar.gz )
fi

mtl_file=$( tar -tzf $L8_tgz | grep 'MTL.txt')
tar -xzf $L8_tgz -C /tmp/ $mtl_file
cat /tmp/$mtl_file | grep RADIANCE_MAXIMUM_BAND_${BAND_NUM} | awk '{print $3}'
rm /tmp/$mtl_file