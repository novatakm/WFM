usage() {
    echo $(basename $0)
    echo "-i <name of the base raster (1km resolution) which is used for building subarea topology>"
    echo "-o <name of the subarea grid vector map>"
    echo "-s <sub_area_size in km>"
    exit 0
}

tmpfn=$$

while getopts i:o:s:h OPT
do
    case $OPT in
        i)
            BASE=$OPTARG
        ;;
        o)
            SUB_AREA=$OPTARG
        ;;
        s)
            SIZE=$OPTARG
        ;;
        h)
            usage
        ;;
        \?)
            usage
        ;;
    esac
done

if [ "$( g.list rast p=$BASE )" = "" ]; then
    exit
fi

eval $( g.region -pgm rast=$BASE )
nsres_m=$nsres
ewres_m=$ewres
eval $( g.region -pg rast=$BASE )
nsres_d=$nsres
ewres_d=$ewres

nsres_D=$(echo $nsres_d $SIZE $nsres_m | awk '{D = ($1*$2*10^3)/$3}END{printf("%f", D)}' )
ewres_D=$(echo $ewres_d $SIZE $ewres_m | awk '{D = ($1*$2*10^3)/$3}END{printf("%f", D)}' )
eval $( g.region -pg nsres=$nsres_D ewres=$ewres_D )
v.mkgrid map=$SUB_AREA grid=$rows,$cols --o