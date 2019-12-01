#! /usr/bin/env python3

import sys
import os
import traceback
import inspect
import subprocess
import re

argsrc_def = "./";
argres_def = "/tmp/countsrc_results";

HEAD_STR = "res";
FLIST_STR = "flist";


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

argsrc = "";
argres = "";

debug = 0;
warning = 0;

if debug:
    warning = 1

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

print( argsrc_def );
print( "debug:%d" % debug );
print( "warning:%d" % warning );

#usage();

#for key, value in ext_ptn.items():
#    print( key + ":" )
#    print( value )


# get env
print(os.environ.get('LANG'))
print(os.environ.get('NEW_KEY'))


def main():
    srctop = os.environ.get( 'SRC_DIR' )

    if srctop == None:
        srctop = argsrc_def

    if argsrc != "":
        srctop = argsrc

    resdir = os.environ.get( 'RES_DIR' )
    if resdir == None:
        resdir = argres_def

    if argres != "":
        resdir = argres

    print( "Source directory :" + str( srctop ) );
    print( "Results directory :" + str( resdir ) );
    
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

#debug = 1
def open_ext_outfh( resd ):
    for kind, value in ext_ptn.items():
        if debug:
            print( ">>> OPEN OUT FH : {}:{}".format( kind, value ) )
        for e in value:
            ext = re.sub( '^MATCH_', '', e)
            key = kind + '.' + ext;
            fname = "{}/{}.{}.{}".format( resd, HEAD_STR, key, FLIST_STR )
            if debug:
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
                    if re.match( '.*/' + ext + '$', fn ) or re.match( '^' + ext + '$', fn ):
                        ext_outfh[ key ].write( fn )
                        print( "OUT {} : {}".format( key, fn ) )
                        out = 1
                else:
                    print( "MMM:" + key + ':' + '.*.' + ext + ":" + fn )
                    if re.match( '.*¥.' + ext, fn ):
                        ext_outfh[ key ].write( fn )
                        print( "OUT {} : {}".format( key, fn ) )
                        out = 1
            if out == 0:
                ext_outfh[ OTHER_KEY ].write( fn )

main()

