#!/usr/bin/env bash

usage() {
    echo $(basename $0)
    echo "-i <name of the input SGLI raster>"
    echo "-o <name of the output SGLI cloud-water-masked raster>"
    echo "-t \"thd_for_CCL thd_for_LWF\""
    exit 0
}

tmpfn=$$

while getopts i:o:t:h OPT
do
    case $OPT in
        i)
            RAST=$OPTARG
        ;;
        o)
            MSKD=$OPTARG
        ;;
        t)
            CCL_LWF_THDS=$OPTARG
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
ccl=$( g.list rast p=$( echo $RAST | cut -c 1-23 )_CCL_Q )
if [ "$( g.list rast p=$RAST | cat )" = "" -o "$ccl" = "" ]; then
    exit 0
fi

snw=$( echo $RAST | cut -c 1-23 )_SNW_Q
cir=$( echo $RAST | cut -c 1-23 )_CIR_Q
lwf=$( echo $RAST | cut -c 1-23 )_LWF_Q
ch=$( echo $RAST | awk 'BEGIN{FS="_"}{print $4"_"$5}' )

g.region rast=$RAST
r.resamp.stats in=$ccl out=ccl$$ method=average --o
r.resamp.stats in=$lwf out=lwf$$ method=average --o
r.resamp.stats in=$snw out=snw$$ method=average --o
r.resamp.stats in=$cir out=cir$$ method=average --o

CCL_THD=$( echo $CCL_LWF_THDS | awk '{print $1}' )
LND_THD=$( echo $CCL_LWF_THDS | awk '{print $2}' )
r.mapcalc "$MSKD = if(ccl$$ >= $CCL_THD && lwf$$ >= $LND_THD && snw$$ == 1 && cir$$ == 1, $RAST, null())"
r.colors map=$MSKD col=grey --o

# 後始末
g.remove -f rast name=ccl$$,lwf$$,snw$$,cir$$
