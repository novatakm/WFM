#!/usr/bin/env bash

usage() {
    echo $(basename $0)
    echo "-i <name of the SGLI obstime raster which is used to create the path identify raster>"
    echo "-o <name of the SGLI orbit path identify raster (250m resoution)>"
    echo "-O <name of the SGLI orbit path identify raster (1km resoution)>"
    exit 0
}

tmpfn=$$

while getopts i:o:O:h OPT
do
    case $OPT in
        i)
            OBSTIME=$OPTARG
        ;;
        o)
            PATH_Q=$OPTARG
        ;;
        O)
            PATH_K=$OPTARG
        ;;
        h)
            usage
        ;;
        \?)
            usage
        ;;
    esac
done

# もし，処理対象とする日の観測データがなければ，処理しない
if [ "$( g.list rast p=${OBSTIME} | cat )" = "" ]; then
    exit 0
fi

g.region rast=${OBSTIME}
r.clump -d inp=${OBSTIME} out=${PATH_Q} --o
r.stats -npl inp=${PATH_Q} sort=asc | \
sed 's/%$//g' | \
awk '{if($2==0){printf("\"'${PATH_Q}' = if('${PATH_Q}' == %d, null(), int('${PATH_Q}'))\"\n", $1)}}' > /tmp/PATHCAT_CMD$FN
cat /tmp/PATHCAT_CMD$FN | awk '{print "r.mapcalc", $0}' | sh
rm /tmp/PATHCAT_CMD$FN

g.region rast=$( echo ${OBSTIME} | sed 's:_OBT_Q$:_RSW04_K:g' )
r.resample inp=${PATH_Q} out=${PATH_K} --o