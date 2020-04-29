#! /usr/bin/env python3

import sys
import os
import traceback
import inspect
import subprocess
import re
import argparse

argsrc = "";
argres = "";

#argsrc_def = "./"
argsrc_def = "./testdata/countsrc"
argres_def = "/tmp/countsrc_results"

# controle print leve
DEBUG = 0;
WARNING = 0;

# constant value
HEAD_STR = "res";
FLIST_STR = "flist";

#
# parse arguments
#
parser = argparse.ArgumentParser(description="count source code")
# exclusive options
group = parser.add_mutually_exclusive_group()
group.add_argument("-v", "--verbose", action="store_true")
group.add_argument("-d", "--debug", action="store_true")
group.add_argument("-q", "--quiet", action="store_true")
# option with value
parser.add_argument("-s", "--srcdir", default=argsrc_def, help="source code direcotry")
parser.add_argument("-r", "--resdir", default=argres_def, help="results direcotry")
# parse !
args = parser.parse_args()

#
# usage:
#
def usage():
    print( """
NAME: countsrc.pl : count source code

SYNOPSIS: countsrc.pl [-v] [-d] [-s <top_dir>] [-r <results_dir>]

DESCRIPTION:
  options :
    -s <source_top_dir>    .... default $argsrc_def
    -r <results_dir>       .... default $argres_def
    -v                     .... print message
    -d                     .... print debug message

  priority of source or results directory :
    option > environment > default

ENVIRONMENT:
    SRC_DIR    .... source code top directory
    RES_DIR    .... results directory

EXAMPLES:
    countsrc.pl
    countsrc.pl -src /usr/local/dev/version1
    countsrc.pl -src /usr/local/dev/version1 -res /var/tmp/countres
""" );
    sys.exit( 1 )


#
# pattern
#
OTHER_KEY = "OTHER.NA"

#OTHER_KEY = bytes( bytearray( "OTHER.NA", 'UTF-8' ) )

ext_ptn = {
    "c"      : ( "c", "h", "pc" ),
    "cpp"    : ( "C", "H", "cpp" ),
    "java"   : ( "java", "jsp", "html" ),
    "shell"  : ( "sh", "csh", "ksh", "bash", "tcsh" ),
    "script" : ( "awk", "nawk", "gawk", "perl", "pl", "py" ),
    "make"   : ( "mk", "MATCH_Makefile", "MATCH_makefile" ),
    "OTHER"  : ( "NA", ),
    }

ext_outfh = {}

def main():
    global DEBUG, WARNING

    srctop = os.environ.get( 'SRC_DIR' )
    if srctop == None:
        srctop = argsrc_def
    if args.srcdir != "":
        srctop = args.srcdir

    resdir = os.environ.get( 'RES_DIR' )
    if resdir == None:
        resdir = argres_def
    if args.resdir != "":
        resdir = args.resdir

    if not args.quiet:
        DEBUG = args.debug
        if args.debug:
            WARNING = True
        else:
            WARNING = args.verbose

    print( "Source directory :" + str( srctop ) );
    print( "Results directory :" + str( resdir ) );
    print( "debug:%d" % DEBUG );
    print( "warning:%d" % WARNING );

    cleanup_dir( resdir );
    countsrc( srctop, resdir );

def cleanup_dir( resdir ):
    print( get_func_name() + ":" + resdir )
    if os.path.isdir( resdir ):
        subprocess.call( "rm -rf " + resdir, shell=True )
    subprocess.call( "mkdir -p " + resdir, shell=True )

def get_func_name():
    return traceback.extract_stack(None, 2)[0][2]

def get_func_args():
    frame = inspect.currentframe().f_back
    args, _, _, values = inspect.getargvalues(frame)
    return ([(i, values[i]) for i in args])

def countsrc( srcd, resd ):
    create_flist( srcd, resd )
#    count_flist( srcd, resd )

def create_flist( srcd, resd ):
    print( get_func_name() + ":" + str( get_func_args() ) )
    open_ext_outfh( resd )
    create_extflist( srcd, resd )
#    close_ext_outfh( resd )

def count_flist( srcd, resd ):
    print( get_func_name() + ":" + str( get_func_args() ) )

def open_ext_outfh( resd ):
    for kind, value in ext_ptn.items():
        if DEBUG:
            print( ">>> OPEN OUT FH : {}:{}".format( kind, value ) )
        for e in value:
            ext = re.sub( '^MATCH_', '', e)
            key = kind + '.' + ext;
            fname = "{}/{}.{}.{}".format( resd, HEAD_STR, key, FLIST_STR )
            if DEBUG:
                print( "open output : {}:{}".format( key, fname ) )
            try:
                ext_outfh[ key ] = open( fname, 'w' )
            except:
                print( "can't open : output : " + fname )


def create_extflist( srcd, resd ):
    print( get_func_name() + ":" + str( get_func_args() ) )

    findcmd = subprocess.Popen(
        [ "find", srcd, "-type", "f" ],
        stdout=subprocess.PIPE )
    ( fhout, fherr ) = findcmd.communicate()
    for fname in fhout.splitlines():
        fn = str( fname )
        out = 0
        for kind, value in ext_ptn.items():
            # print( kind, value )
            for extptn in value:
                ext = re.sub( '^MATCH_', '', extptn )
                key = kind + '.' + ext;
                if re.match( "^MATCH_", extptn ):
                    bn = os.path.basename( fn )[:-1]
#                    print( "MATCH:" + key + ': (' + bn + '==' + ext + ') :' + fn )
                    if ext == bn:
                        ext_outfh[ key ].write( fn )
                        print( "OUT {} : {}".format( key, fn ) )
                        out = 1
                else:
#                    print( "EXT:" + key + ':' + '.*.' + ext + ":" + fn )
                    if re.match( '.*\.' + ext, fn ):
                        ext_outfh[ key ].write( fn )
                        print( "OUT {} : {}".format( key, fn ) )
                        out = 1
            if out == 0:
                ext_outfh[ OTHER_KEY ].write( fn )

main()
