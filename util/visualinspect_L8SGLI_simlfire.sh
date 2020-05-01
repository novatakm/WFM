#!/usr/bin/env bash

if [ "$1" = "-h" ]; then
    echo "$(basename $0) FROM_DATE(YYYYMMDD) NUM_OF_DATE TILE_NUM(V**H**)"
    exit
fi

FN=$$
FROM_DATE=$1
NUM_OF_DATE=$2
TILE_NUM=$3

sagrd=SAGRD_${TILE_NUM}_100KM

g.region rast=GC1SG1_${FROM_DATE}D_${TILE_NUM}_RSW03_Q
: > mday_rgb_cmd.log
d.erase
for n_date in $(jot ${NUM_OF_DATE} 0)
do
    date=$(date '+%Y%m%d' --date "+${n_date} days ${FROM_DATE}")
    vn11=GC1SG1_${date}D_${TILE_NUM}_RVN11_Q
    sw3=GC1SG1_${date}D_${TILE_NUM}_RSW03_Q
    sw4=GC1SG1_${date}D_${TILE_NUM}_RSW04_K
    d.rgb r=${sw4} g=${sw3} b=${vn11}
    echo "d.rgb r=${sw4} g=${sw3} b=${vn11}" >> mday_rgb_cmd.log
done
#d.vect ${sagrd} type=boundary col="red"
#echo "d.vect ${sagrd} type=boundary col=\"red\"" >> mday_rgb_cmd.log
