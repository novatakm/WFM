#!/usr/bin/env bash

usage(){
    echo $( basename $0 )
    echo "-i <text file which contains SGLI FRP estimation result>"
    echo "-o <output SGLI FRP estimation vector>"
    echo "-h help"
    exit
}

while getopts i:o:h  OPT
do
    case $OPT in
        i)
            FRP_FILE=$OPTARG
        ;;
        o)
            FRP_VECT=$OPTARG
        ;;
        h)
            usage
        ;;
    esac
done

g.mapset map=INTMED
g.region -d
v.in.ascii in=${FRP_FILE} output=${FRP_VECT} sep=space \
columns="lon double precision, lat double precision, L_sw04 double precision, Lb_sw04 double precision, L_sw03 double precision, Lb_sw03 double precision, SGLI_obstime double precision, Pf double precision, corr_Pf double precision, isval_sw04 int, isval_sw03 int, Tf double precision, SSE double precision, success varchar(10), FRP double precision" --o