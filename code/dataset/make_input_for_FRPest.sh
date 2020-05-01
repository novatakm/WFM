#!/usr/bin/env bash

usage() {
    echo $(basename $0)
    echo "-g <GISDBASE>"
    echo "-t <tile number (in VxxHxx format)>"
    echo "-p <name of the file which contains the parameters for fire prop. estimation>"
    echo "-d <obs_date in YYYYMMDD[A|D] format>"
    exit 0
}

FN=$$

while getopts g:t:d:p:h OPT
do
    case $OPT in
        g)
            GISDBASE=$OPTARG
        ;;
        d)
            OBS_DATE=$OPTARG
        ;;
        t)
            TILE=$OPTARG
        ;;
        p)
            PEST_PARAM_FILE=$OPTARG
        ;;
        h)
            usage
        ;;
        \?)
            usage
        ;;
    esac
done


g.mapset map=INTMED
g.region rast=GC1SG1_${OBS_DATE}_${TILE}_RSW04_K
r.resamp.stats in=GC1SG1_${OBS_DATE}_${TILE}_MCRSW03_Q out=GC1SG1_${OBS_DATE}_${TILE}_MCRSW03_K method="average" --o
r.resamp.stats in=GC1SG1_${OBS_DATE}_${TILE}_SGLIREFFIRE_Q out=GC1SG1_${OBS_DATE}_${TILE}_SGLIREFFIRE_K method="maximum" --o
r.null map=GC1SG1_${OBS_DATE}_${TILE}_SGLIREFFIRE_K null=0 --o
r.mapcalc "GC1SG1_${OBS_DATE}_${TILE}_SGLIREFFIRE_K = int(GC1SG1_${OBS_DATE}_${TILE}_SGLIREFFIRE_K)"
r.colors map=GC1SG1_${OBS_DATE}_${TILE}_MCRSW03_K col=grey --o


eval $( cat $PEST_PARAM_FILE )
r.mask rast=GC1SG1_${OBS_DATE}_${TILE}_SGLIREFFIRE_K maskcat=1
r.mapcalc "DLT = (GC1SG1_${OBS_DATE}_${TILE}_MCRSW04_K - GC1SG1_${OBS_DATE}_${TILE}_MCRSW03_K)*MASK"
r.mapcalc "GC1SG1_${OBS_DATE}_${TILE}_PfEST_K = 1/(1 + exp(-($b0 + $b1*DLT)))"
r.mask -r
g.remove -f rast name=DLT

out_dir=$GISDBASE/../INTMED/$( basename $0 | sed 's:.sh$::g' )/GC1SG1_${OBS_DATE}_${TILE}
mkdir -p $out_dir
r.mapcalc "MCRSW04_FMASKD = if(GC1SG1_${OBS_DATE}_${TILE}_SGLIREFFIRE_K == 1, null(), GC1SG1_${OBS_DATE}_${TILE}_MCRSW04_K)"
r.mapcalc "MCRSW03_FMASKD = if(GC1SG1_${OBS_DATE}_${TILE}_SGLIREFFIRE_K == 1, null(), GC1SG1_${OBS_DATE}_${TILE}_MCRSW03_K)"
for size in 5 7 9 11
do
    r.neighbors inp=MCRSW04_FMASKD out=MCRSW04_BKG method="average" size=$size --o
    r.neighbors inp=MCRSW03_FMASKD out=MCRSW03_BKG method="average" size=$size --o
    r.mask rast=GC1SG1_${OBS_DATE}_${TILE}_SGLIREFFIRE_K maskcat=1
    r.stats -1ng in=GC1SG1_${OBS_DATE}_${TILE}_MCRSW04_K,MCRSW04_BKG,GC1SG1_${OBS_DATE}_${TILE}_MCRSW03_K,MCRSW03_BKG,GC1SG1_${OBS_DATE}_${TILE}_OBT_Q,GC1SG1_${OBS_DATE}_${TILE}_PfEST_K > $out_dir/FRPest_input_BKG$size.txt
    r.mask -r
done

g.remove -f rast p="MCRSW*"