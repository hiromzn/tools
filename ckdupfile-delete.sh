#!/bin/env sh
# $Header: /data/cvsrepo/assess-tools/tools/ckdupfile-delete.sh,v 1.1 2014/08/15 05:18:09 hmizuno Exp $
# $Name: rev_1_10 $

#
# ckdupfileの結果ファイルを参照して同じファイルを
# 1つだけ残して他のファイルを削除するツール
#
# 使い方：
#  ckdupfile-delete.sh <ckdupfile.shの結果ディレクトリ>
#

if [ ! -s "$1/results" ] ;then
	echo "ERROR : check results file ($1/results)"
	echo "usage : $0 results_directory(res_XXXXXXX)"
else
cat $1/results \
	|grep ^SAME \
	|awk -F: '{ printf( "flist_%08d %s\n", $2, $5 ); }' \
	|sed 's/)//' \
	|while read fname n
	do
		deln=`expr $n - 1`;
		alln=`cat $1/$fname |wc -l`;
		echo "##### $fname : all:$alln :del:$deln";
		echo "rm `head -$deln $1/$fname`";
		rm `head -$deln $1/$fname`;
	done
fi
