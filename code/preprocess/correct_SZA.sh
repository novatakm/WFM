#!/usr/bin/env bash
usage() {
    echo $(basename $0)
    echo "-i <name of the SGLI TOA reflectance raster>"
    echo "-o <name of the SGLI SZA-corrected TOA reflectance raster>"
    exit 0
}

tmpfn=$$

while getopts i:o:h OPT
do
    case $OPT in
        i)
            TOA_REF=$OPTARG
        ;;
        o)
            COR_REF=$OPTARG
        ;;
        h)
            usage
        ;;
        \?)
            usage
        ;;
    esac
done

toa_ref=$( g.list rast p=${TOA_REF} | cat )

case $toa_ref in
    "")
        exit
    ;;
    *)
        sza=$( echo $toa_ref | cut -c 1-23 )_SZA_Q
        ch=$( echo $toa_ref | cut -c 25-31 )
        g.region rast=$toa_ref
        r.mapcalc "${COR_REF} = ${toa_ref}/cos(${sza})"
        r.colors map=${COR_REF} col=grey --o
    ;;
esac
