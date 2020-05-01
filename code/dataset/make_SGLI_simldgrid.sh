usage() {
    echo $(basename $0)
    echo "-i <L8_reffire_vector>"
    echo "-o <output simulated SGLI vector>"
    echo "-d <dir to where simld SGLI data is dumped as txt file>"
    exit 0
}

FN=$$

while getopts i:o:d:h OPT
do
    case $OPT in
        i)
            L8_REFFIRE_VECT=$OPTARG
        ;;
        o)
            SGLISIMLD=$OPTARG
        ;;
        d)
            OUT_DIR=$OPTARG
        ;;
        h)
            usage
        ;;
        \?)
            usage
        ;;
    esac
done

SGLI_data_id=$( echo $L8_REFFIRE_VECT | awk 'BEGIN{FS="_"}{print $1"_"$2"_"$3}' )
L8_data_id=$( echo $L8_REFFIRE_VECT | awk 'BEGIN{FS="_"}{print $4"_"$5"_"$6"_"$7}' )
tile=$( echo $L8_REFFIRE_VECT | awk 'BEGIN{FS="_"}{print $3}' )
eval $( g.region -pg rast=${L8_data_id}_L7 ); L8_nsres=$nsres; L8_ewres=$ewres
eval $( g.region -pg rast=${SGLI_data_id}_RSW04_K); SGLI_nsres=$nsres; SGLI_ewres=$ewres
eval $( g.region -pg vect=${L8_REFFIRE_VECT} ); REFFIRE_n=$n; REFFIRE_s=$s; REFFIRE_e=$e; REFFIRE_w=$w;
n=$( echo $REFFIRE_n $SGLI_nsres | awk '{print $1+$2*5}' )
s=$( echo $REFFIRE_s $SGLI_nsres | awk '{print $1-$2*5}' )
e=$( echo $REFFIRE_e $SGLI_ewres | awk '{print $1+$2*5}' )
w=$( echo $REFFIRE_w $SGLI_ewres | awk '{print $1-$2*5}' )
eval $( g.region -pg rast=${SGLI_data_id}_RSW04_K n=$n s=$s e=$e w=$w )
#  g.region -pgm
v.mkgrid map=${SGLISIMLD} grid=$rows,$cols --o
g.region nsres=$L8_nsres ewres=$L8_ewres
v.rast.stats -c map=${SGLISIMLD} rast=${L8_data_id}_L7 column_pref=l7 method="average"
v.rast.stats -c map=${SGLISIMLD} rast=${L8_data_id}_R7 column_pref=r7 method="average"
v.rast.stats -c map=${SGLISIMLD} rast=${L8_data_id}_PR7 column_pref=pr7 method="average"
v.rast.stats -c map=${SGLISIMLD} rast=${L8_data_id}_L6 column_pref=l6 method="average"
v.rast.stats -c map=${SGLISIMLD} rast=${L8_data_id}_R6 column_pref=r6 method="average"
v.rast.stats -c map=${SGLISIMLD} rast=${L8_data_id}_PR6 column_pref=pr6 method="average"
v.rast.stats -c map=${SGLISIMLD} rast=${L8_data_id}_L7 column_pref=pixcount method="number"
v.vect.stats points=${L8_REFFIRE_VECT} areas=${SGLISIMLD} count_col=firecount points_col=l7 stats_column=firel7sum method=sum
l7_max=$( $DENV_UTIL/get_L8_maxrad.sh -n ${L8_REFFIRE_VECT} -b 7 -t ${tile} )
v.db.addcolumn map=${SGLISIMLD} col="l7_max double precision"
v.db.update map=${SGLISIMLD} col="l7_max" val=$l7_max
# v.vect.stats points=${L8_REFFIRE_VECT} areas=${SGLISIMLD} points_col=l7 stats_column=firel7sum method=sum

out_dir=$OUT_DIR/$( basename $0 | sed 's:.sh$::g' ); mkdir -p $out_dir
out_file=$out_dir/${SGLISIMLD}_L6_L7_R6_R7_PR6_PR7_FL7SUM_L7MAX_FCNT_PCNT.txt
v.db.select -c map=${SGLISIMLD} col=l6_average,l7_average,r6_average,r7_average,pr6_average,pr7_average,firel7sum,l7_max,firecount,pixcount_number where="firecount > 0" sep=" " > $out_file