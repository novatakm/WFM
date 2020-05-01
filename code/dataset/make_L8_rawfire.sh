#!/usr/bin/env bash

usage() {
    echo $(basename $0)
    echo "-i <name of the L8-SGLI siml.-observd. timegap raster>"
    echo "-o <name of the L8-raw-detection point vector>"
    echo "-s <output L8-raw-detection shape file>"
    exit 0
}

tmpfn=$$

while getopts i:o:s:h OPT
do
    case $OPT in
        i)
            TGAP=$OPTARG
        ;;
        o)
            RAWFIRE=$OPTARG
        ;;
        s)
            SHP=$OPTARG
            mkdir -p $SHP
        ;;
        h)
            usage
        ;;
        \?)
            usage
        ;;
    esac
done

#もし，同期観測ラスタTGAPが存在しなければ，処理しない。
if [ "$( g.list rast p=$TGAP)" = "" ]; then
    exit
fi

#SGLIおよびL8データIDの抽出
SGLI_data_id=$( echo $TGAP | awk 'BEGIN{FS="_"; OFS="_"}{print $1,$2,$3}')
L8_data_id=$( echo $TGAP | awk 'BEGIN{FS="_"; OFS="_"}{print $4,$5,$6,$7}')

g.region rast=${L8_data_id}_R7
#Landsat8火災検知データを，ポイントデータとしてShapefileで出力
#付与する属性は，
# time_gap: SGLIとの観測時間ズレ（単位はhour）
# l6: バンド6の観測輝度
# l7: バンド7の観測輝度
# r6: バンド6のTOA反射率
# r7: バンド7のTOA反射率
# is_fire: 火災・非火災分類のためのカテゴリ番号
# 0: raw L8 detections
# 1: fire
# 2: bright soil
# 3: construction
# 4: bright object (ex. solar panel)
# 5: industrial
# 6:
# 7:
# comment: 任意のコメント
r.to.vect in=${TGAP} out=${RAWFIRE} col="time_gap" type=point --o
v.db.addcolumn map=${RAWFIRE} columns="l6 double precision, l7 double precision, r6 double precision, r7 double precision, is_fire integer, comment varchar(64)"
v.what.rast map=${RAWFIRE} type=point raster=${L8_data_id}_L6 column="l6" --o
v.what.rast map=${RAWFIRE} type=point raster=${L8_data_id}_L7 column="l7" --o
v.what.rast map=${RAWFIRE} type=point raster=${L8_data_id}_PR6 column="r6" --o
v.what.rast map=${RAWFIRE} type=point raster=${L8_data_id}_PR7 column="r7" --o
v.db.update map=${RAWFIRE} column="is_fire" value="0" --o
v.out.ogr in=${RAWFIRE} type=point out=$SHP format="ESRI_Shapefile" --o

#Landsat8 カラーコンポジット画像(R:G:B=7:6:2, R:G:B=4:3:2)をGTiff形式で出力
r.out.gdal in=${L8_data_id}_B7 out=/tmp/L8_B7.tif format="GTiff" createopt="PROFILE=GeoTIFF" --o
r.out.gdal in=${L8_data_id}_B6 out=/tmp/L8_B6.tif format="GTiff" createopt="PROFILE=GeoTIFF" --o
r.out.gdal in=${L8_data_id}_B4 out=/tmp/L8_B4.tif format="GTiff" createopt="PROFILE=GeoTIFF" --o
r.out.gdal in=${L8_data_id}_B3 out=/tmp/L8_B3.tif format="GTiff" createopt="PROFILE=GeoTIFF" --o
r.out.gdal in=${L8_data_id}_B2 out=/tmp/L8_B2.tif format="GTiff" createopt="PROFILE=GeoTIFF" --o
gdal_merge.py -o $SHP/L8_762.tif -co COMPRESS=LZW -separate /tmp/L8_B7.tif /tmp/L8_B6.tif /tmp/L8_B2.tif
gdal_merge.py -o $SHP/L8_432.tif -co COMPRESS=LZW -separate /tmp/L8_B4.tif /tmp/L8_B3.tif /tmp/L8_B2.tif
#tmpファイルの後始末
rm /tmp/L8_B*.tif /tmp/L8_B*.tif.aux.xml

#SGLI カラーコンポジット画像(R:G:B=7:6:11)をGTiff形式で出力
r.composite r=${SGLI_data_id}_RSW04_K g=${SGLI_data_id}_RSW03_Q b=${SGLI_data_id}_RVN11_Q out=SG_4311_$$ --o
r.out.gdal in=SG_4311_$$ out=$SHP/SG_4311.tif format="GTiff" createopt="PROFILE=GeoTIFF" --o
#tmpファイルの後始末
g.remove -f rast name=SG_4311_$$