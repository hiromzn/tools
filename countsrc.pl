#! /usr/bin/perl

use Getopt::Long;

my $argsrc_def = "./";
my $argres_def = "/tmp/countsrc_results";

#
# usage:
#
sub usage
{
    my $msg = "
usage : countsrc.pl : count source code

Option : 
    -s <source_top_dir>    .... default $argsrc_def
    -r <results_dir>       .... default $argres_def

environment : 
    SRC_DIR    .... source code top directory
    RES_DIR    .... results directory

priority of source or results directory :
    option > environment > default

sample operation:
    countsrc.pl
    countsrc.pl -src /usr/local/dev/version1
    countsrc.pl -src /usr/local/dev/version1 -res /var/tmp/countres
";
    print $msg;
    exit 1;
}

my $argsrc = "";
my $argres = "";

GetOptions(
    's=s' => \$argsrc, # source top directory
    'r=s' => \$argres, # results directory
    ) or usage();

#
# file extention list
#
my @extlist = (
    "c",
    "h",
    "pc",
    "C",
    "H",
    "cpp",
    "java",
    "jsp",
    "html",
    "sh",
    "csh",
    "ksh",
    "bash",
    "tcsh",
    "awk",
    "nawk",
    "gawk",
    "perl",
    "pl",
    "py",
    );

my %ext_outfh;
my $OTHER_FH;

sub open_ext_outfh
{
    my( $resd ) = @_;
    
    foreach $ext (@extlist) {
	# printf( "open output : ext: %s\n", $ext );
	open( $ext_outfh{ $ext }, ">$resd/flist.$ext.list" )
	    or die( "can't open : output : >$resd/flist.$ext.list\n" );
    }
    # printf( "open output : ext: OTHER\n", $ext );
    open( OTHER_OUTF, ">$resd/flist.OTHER.list" )
	or die( "can't open : output : >$resd/flist.OTHER.list\n" );
}
sub close_ext_outfh
{
    my( $resd ) = @_;
    
    foreach $ext (@extlist) {
	close( $ext_outfh{ $ext } )
	    or die( "can't close FH: >$resd/flist.$ext.list\n" );
    }
    close( OTHER_OUTF )
	or die( "can't close FH: >$resd/flist.OTHER.list\n" );
}

sub create_extflist
{
    my( $srcd, $resd, $ext ) = @_;
    
    open( FIND, "find $srcd -type f |" ) or die( "can't open : command : find $srcd -type f |\n" );
    
    while( <FIND> ) {
	chop();
	my $fn = $_;
	my $out = 0;
	foreach $ext (@extlist) {
	    if ( "$fn" =~ /\.$ext$/ ) {
		# printf( "# $ext : $fn\n" );
		printf( { $ext_outfh{ $ext } } "$fn\n" );
		$out = 1;
	    }
	}
	if ( ! $out ) {
	    # printf( "# OTHER : $fn\n" );
	    printf( OTHER_OUTF "$fn\n" );
	}
    }
}    

sub create_flist
{
    my( $srcd, $resd ) = @_;
    open_ext_outfh( $resd );
    create_extflist( $srcd, $resd );
    close_ext_outfh( $resd );
}

sub count_flist
{
    my( $srcd, $resd ) = @_;
    
    foreach $ext (@extlist, "OTHER") {
	if ( -s "$resd/flist.$ext.list" ) {
	    printf( "RESULTS : %8s : total line: ", "$ext" );
	    system( "cat $resd/flist.$ext.list |LANG=C xargs wc |tee $resd/flist.$ext.wc |tail -1 |sed 's/^ *//' |cut '-d ' -f1" );
	} else {
	    printf( stderr "message : %8s : no file\n", "$ext" );
	}
    }
}

sub countsrc
{
    my( $srcd, $resd ) = @_;
    create_flist( $srcd, $resd );
    count_flist( $srcd, $resd );
}

sub cleanup_dir
{
    my( $dir ) = @_;
    if ( -d "$dir" ) {
        system( "rm -rf $dir" );
    }
    system( "mkdir -p $dir" );
}

sub main
{
    $srctop = $ENV{'SRC_DIR'};
    if ( "$srctop" eq "" ) {
        $srctop = $argsrc_def;
    }
    if ( "$argsrc" ne "" ) {
        $srctop = $argsrc;
    }

    $resdir = $ENV{'RES_DIR'};
    if ( "$resdir" eq "" ) {
        $resdir = $argres_def;
    }
    if ( "$argres" ne "" ) {
        $resdir = $argres;
    }

    print "Source directory :$srctop\n";
    print "Results directory :$resdir\n";
    
    cleanup_dir( $resdir );
    countsrc( $srctop, $resdir );
}

main;
