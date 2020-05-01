#!/usr/bin/env bash

usage(){
    echo $( basename $0 )
    echo "-i <path to the directory which contains input data >"
    echo "-h help"
    exit
}

while getopts i:h  OPT
do
    case $OPT in
        i)
            INP_DIR=$OPTARG
        ;;
        h)
            usage
        ;;
    esac
done

g.mapset map=INTMED

for region_name in US WAUS INDNS ALLREGION
do
    Rscript $DENV_CODE/model/fit_fireprop_regression_netfpcount.r \
    ${INP_DIR}/${region_name}/SGLISIMLDGRID_L6_L7_R6_R7_PR6_PR7_FL7SUM_L7MAX_FCNT_PCNT.txt \
    ${INP_DIR}/${region_name}/fit.txt
done