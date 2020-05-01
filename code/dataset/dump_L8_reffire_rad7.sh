usage() {
    echo $(basename $0)
    echo "-i <L8_reffire_vector>"
    echo "-o <dir to where L8 band7 radiance summation summary is dumped as txt file>"
    exit 0
}

FN=$$

while getopts i:o:h OPT
do
    case $OPT in
        i)
            L8_REFFIRE_VECT=$OPTARG
        ;;
        o)
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

if [ "$( g.list vect p=${L8_REFFIRE_VECT} )" = "" ]; then
    exit
fi

L8_data_id=$( echo ${L8_REFFIRE_VECT} | awk 'BEGIN{FS="_"}{print $4"_"$5"_"$6"_"$7}' )
g.region rast=${L8_data_id}_PR7
#eval $( v.univar -g map=${L8_REFFIRE_VECT} where="is_fire = 1" col="l7" )
out_dir=$OUT_DIR/$( basename $0 | sed 's:.sh$::g' )
mkdir -p $out_dir
v.db.select -c map=${L8_REFFIRE_VECT} col="l7" where="is_fire = 1" sep=" " > $out_dir/${L8_data_id}.txt