#!/bin/sh
# $Header: /data/cvsrepo/assess-tools/tools/mkxref.sh,v 1.3 2013/10/09 05:22:38 hmizuno Exp $
# $Name: rev_1_10 $

myprog=$0

usage()
{
cat <<EOF_USAGE
#
# make cross reference
#

usage:
  $myprog [-o] [-f <filelist>] <topdir>

arguments:
   <topdir> .... top directory which has all target source files.

options:
  -o ..... include own filename reference
           default : don't include own filename reference

  -f ..... specify check file list
           default : all file name in <topdir>

output:
  ./res_<timestr>/ ..... directory which has all results fles.
  ./res_<timestr>/flist ... file list (without file path)
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

# for command option variables

# FLIST flag : 1 = file_list is specified by -f option
FLIST_FLAG=0;

# flag for checking own shell name
INCLUDE_OWN_NAME=0;

FLIST=$RESULTS_DIR/flist
RESULT_FILE=$RESULTS_DIR/results
ALL_FLIST=$RESULTS_DIR/allfilelist
TMPFILE=$RESULTS_DIR/tmpfile

pr_runenv()
{
cat <<EOF_PR_ENV
source dir     : $topdir

results:
 results dir    : $RESULTS_DIR
 file list      : $FLIST ($OPTFLIST)
 result file    : $RESULT_FILE
 all file list  : $ALL_FLIST
 tmp file       : $TMPFILE

FLIST_FLAG       : $FLIST_FLAG
INCLUDE_OWN_NAME : $INCLUDE_OWN_NAME

EOF_PR_ENV
}

checkargs()
{
    while [ "$#" -gt 1 ];
    do
      case "$1" in
      "-f" ) # specify flist
	  OPTFLIST=$2;
	  if [ ! -s "$OPTFLIST" ]; then
	      echo "ERROR : $OPTFLIST file does NOT exist or is empty." 1>&2
	      echo "" 1>&2
	      usage;
	  fi
	  FLIST_FLAG=1;
	  shift;
	  ;;
      "-o" ) # include own shell name into result
	  INCLUDE_OWN_NAME=1;
	  ;;
      esac
      shift;
    done

    if [ $# -ne 1 ]; then
	usage;
    fi

    topdir=$1
    if [ ! -d "$topdir" ]; then
	echo "ERROR : top directory is invalid. ($topdir)" 1>&2
	echo "" 1>&2
	usage;
    fi
    pr_runenv;
}

setenv()
{
    if [ ! -d "$RESULTS_DIR" ];
    then
	mkdir -p $RESULTS_DIR
    fi
}

delcomment()
{
    sed 's/#.*//g'
}

pr_xref()
{
    file=$1;
    myfname=`basename $file`;
    resstr="";
    while read fname
    do
      if [ "$INCLUDE_OWN_NAME" -eq 1 -o "$myfname" != "$fname" ]; then
	  cat $file |delcomment >$TMPFILE
	  grep "$fname" $TMPFILE >/dev/null 2>&1
	  if [ $? -eq 0 ]; then
	      resstr="$resstr $fname";
	  fi
	  rm -f $TMPFILE
      fi
    done
    if [ ! -z "$resstr" ]; then
	echo "$file $resstr";
    fi
}

getallflist()
{
    find $topdir -type f
}

getflist()
{
    sed 's/.*\///' |sort |uniq
}

make_xref()
{
    while read fpath
    do
      cat $FLIST |pr_xref $fpath
    done <$ALL_FLIST
}

pr_results()
{
cat <<EOF
###############################
check the following files.
###############################

RESULTS files:
  $FLIST : uniq fle name list
        format : <fname>

  $RESULT_FILE : results file (copy of stdout)

EOF
}

main_func()
{
    checkargs $*;
    setenv;
    getallflist >$ALL_FLIST
    if [ "$FLIST_FLAG" -eq 0 ]; then
	cat $ALL_FLIST |getflist >$FLIST
    else
	cp $OPTFLIST $FLIST
    fi

    make_xref |tee $RESULT_FILE
}

main()
{
    main_func $*
}

main $*;

exit 0;
