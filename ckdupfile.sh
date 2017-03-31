#!/bin/sh
# $Header: /data/cvsrepo/assess-tools/tools/ckdupfile.sh,v 1.7 2014/10/15 06:51:47 hmizuno Exp $
# $Name: rev_1_10 $

myprog=$0
topdir=$1

usage()
{
cat <<EOF_USAGE
#
# check duplicate file
#

usage:
  $myprog <topdir>

arguments:
   <topdir> .... top directory which has all target source files.

output:
  ./res_<timestr>/ ..... directory which has all results fles.
  ./res_<timestr>/dupflist ... duplicate file list (without file path)
  ./res_<timestr>/flist_list ... duplicate file list with serial number
                              format : n filename
  ./res_<timestr>/flist_DDDDDDDD ... all duplicate file name in <n>
                              format : file name with path...
  ./res_<timestr>/results ... results file
  ./res_<timestr>/allfilelist ... all target filelist with path

return:
  0 : success
  not 0 : error
EOF_USAGE
    exit 1;
}

timestr=`date +%Y-%m%d-%H%M-%S`

RESULTS_DIR=./res_$timestr

DUPFLIST=$RESULTS_DIR/dupflist
FLIST_BASE=$RESULTS_DIR/flist
FLIST_LIST=${FLIST_BASE}_list
RESULT_FILE=$RESULTS_DIR/results
ALL_FLIST=$RESULTS_DIR/allfilelist

checkargs()
{
    if [ $# -ne 1 ]; then
	usage;
    fi
    if [ ! -d "$topdir" ]; then
	echo "ERROR : top directory is invalid. ($topdir)"
	echo ""
	usage;
    fi
}

setenv()
{
    if [ ! -d "$RESULTS_DIR" ];
    then
	mkdir -p $RESULTS_DIR
    fi
}


get_n_flist_name()
{
    printf "${FLIST_BASE}_%08d" $1;
}

getdupflist()
{
    touch ${FLIST_LIST};
    n=0;
    find $topdir -type f |tee $ALL_FLIST \
	|sed 's/.*\///' \
	|sort |uniq -c \
	|awk '{ if ($1 > 1) { print $2 } }' >$DUPFLIST
    while read fname
    do
      n=`expr $n + 1`;
      nfname=`get_n_flist_name $n`;
      find $topdir -type f -name $fname >$nfname;
      echo "$n $fname" >>${FLIST_LIST};
    done <$DUPFLIST
    max_n=$n;
}

diff_files()
{
    num=$1;
    fname=$2
    count=$3;

    infile=`get_n_flist_name $num`;
    top="";
    n=0;
    nok=1;
    while read f
    do
      if [ -z "$top" ]; then
	  top=$f;
      else
	  diff $top $f >/dev/null 2>&1
	  if [ $? -ne 0 ]; then
	      echo "DIFF:$num:$fname:(count:$count) $top $f"
	  else
              nok=`expr $nok + 1`;
	  fi
      fi
      n=`expr $n + 1`;
    done <$infile
    if [ $n -eq $nok ]; then
	echo "SAME:$num:$fname:(count:$count)"
    fi
}

check_files()
{
    while read n fname
    do
      nfname=`get_n_flist_name $n`;
      count=`cat $nfname |wc -l`;
      diff_files $n $fname $count
    done <${FLIST_LIST}
}

pr_results()
{
ftop=`get_n_flist_name 1`;
fend=`get_n_flist_name $max_n`;

cat <<EOF
###############################
check the following files.
###############################

ENVIRONMENT:
  hostname : `hostname`
  current working directory : `pwd`
  top directory of source fie : $topdir

RESULTS files:
  $DUPFLIST : duplicate fle name list
        format : <fname>

  ${FLIST_LIST} : duplicate fle name and number list
        format : <n> <fname>

  $ftop
  $fend : duplicate name file 
        format : <fname_with_path>

  $RESULT_FILE : results file (copy of stdout)

RESULTS:
  total number of duplicate file  : $max_n
  number of duplicate file (SAME) : $num_same
  number of duplicate file (DIFF) : $num_diff
EOF
}

main_func()
{
    checkargs $*;
    setenv;
    getdupflist;

    check_files |tee $RESULT_FILE

    num_same=`cat $RESULT_FILE |grep '^SAME:' |wc -l`;
    num_diff=`cat $RESULT_FILE |grep '^DIFF:' |wc -l`;

    pr_results |tee -a $RESULT_FILE
}

main()
{
    main_func $*
}

main $*;

exit 0;
