#!/usr/bin/env bash

if [ "$1" = "-h" ]; then
    echo "$(basename $0) OBS_DATE(YYYYMMDD) [D|A]"
    exit
fi

FN=$$
OBS_DATE=$1
DA=$2
TILE_NUM=$( basename $( dirname $( g.gisenv GISDBASE ) ) )

g.region rast=GC1SG1_${OBS_DATE}${DA}_${TILE_NUM}_RSW03_Q
vn11=GC1SG1_${OBS_DATE}${DA}_${TILE_NUM}_RVN11_Q
sw3=GC1SG1_${OBS_DATE}${DA}_${TILE_NUM}_RSW03_Q
sw4=GC1SG1_${OBS_DATE}${DA}_${TILE_NUM}_RSW04_K
d.rgb r=${sw4} g=${sw3} b=${vn11}
for mod14 in $( g.list vect p="MODIS_${OBS_DATE}${DA}_*" | cat )
do
    d.vect ${mod14} type=boundary col=red
done