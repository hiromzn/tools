#! /usr/bin/perl

use Getopt::Long;

my $argsrc_def = "./";
my $argres_def = "/tmp/countsrc_results";

my $HEAD_STR = "res";
my $FLIST_STR = "flist";

#
# usage:
#
sub usage
{
	my $msg = "
NAME: countsrc.pl : count source code

SYNOPSIS: countsrc.pl [-v] [-d] [-s <top_dir>] [-r <results_dir>] 

DESCRIPTION: 
  options :
	-s <source_top_dir>	   .... default $argsrc_def
	-r <results_dir>	   .... default $argres_def
	-v					   .... print message
	-d					   .... print debug message

  priority of source or results directory :
	option > environment > default

ENVIRONMENT:
	SRC_DIR	   .... source code top directory
	RES_DIR	   .... results directory

EXAMPLES:
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
	'v' => \$warning,  # print message
	'd' => \$debug,	   # print debug
	) or usage();

if ( $debug ) {
	$warning = 1;
}

#
# pattern
#
$OTHER_KEY="OTHER.NA";

my %ext_ptn = (
	"c", "c h",
	"proc", "pc",
	"cpp", "C H cpp hpp",
	"java", "java jsp html",
	"shell", "sh csh ksh bash tcsh",
	"script", "awk nawk gawk perl pl py",
	"make", "mk MATCH_Makefile MATCH_makefile",
	"OTHER", "",
	);

my %ext_outfh;

sub open_ext_outfh
{
	my( $resd ) = @_;

	while( ( $kind, $value ) = each ( %ext_ptn ) ) {
		@ext_ary = split( ' ', $value );
		if ( $#ext_ary < 0 ) {
			@ext_ary = ( "NA" ); # OTHER.NA
		}
		foreach $ext (@ext_ary) {
			$ext =~ s/^MATCH_//;
			$key = $kind . '.' . $ext;
			printf( "open output : key: %s\n", $key ) if ( $debug );
			open( $ext_outfh{ $key }, ">$resd/$HEAD_STR.$key.$FLIST_STR" )
				or die( "can't open : output : >$resd/$HEAD_STR.$key.$FLIST_STR\n" );
		}
	}
}

sub close_ext_outfh
{
	my( $resd ) = @_;
	
	while ( ( $key, $fh ) = each( %ext_outfh ) ) {
		printf( "close : $key\n" ) if ( $debug );
		close( $fh )
			or die( "can't close FH: >$resd/$HEAD_STR.$key.$FLIST_STR\n" );
	}
}

sub create_extflist
{
	my( $srcd, $resd ) = @_;
	
	open( FIND, "find $srcd -type f |" ) or die( "can't open : command : find $srcd -type f |\n" );
	
	while( <FIND> ) {
		chop();
		my $fn = $_;
		my $out = 0;

		printf( "DEBUG:flist:###FILE$fn\n" ) if($debug);
		while( ( $kind, $value ) = each ( %ext_ptn ) ) {
			printf( "DEBUG:flist:##KIND:$kind\n" ) if($debug);
			@ext_ary = split( ' ', $value );
			foreach $extptn (@ext_ary) {
				printf( "DEBUG:flist:#EXT:$extptn\n" ) if($debug);
				$ext = $extptn;
				$ext =~ s/^MATCH_//;
				$key = $kind . '.' . $ext;
				if ( $extptn =~ /^MATCH_/ ) {
					if ( ( "$fn" =~ /\/$ext$/ ) || ( "$fn" =~ /^$ext$/ ) ) {
						printf( { $ext_outfh{ $key } } "$fn\n" );
						printf( "DEBUG:flist:$key:$fn\n" ) if($debug);
						$out = 1;
						break;
					}
				} else {
					if ( "$fn" =~ /\.$ext$/ ) {
						printf( { $ext_outfh{ $key } } "$fn\n" );
						printf( "DEBUG:flist:$key:$fn\n" ) if($debug);
						$out = 1;
						break;
					}
				}
			}
		}
		if ( ! $out ) {
			printf( { $ext_outfh{ $OTHER_KEY } } "$fn\n" );
			printf( "DEBUG:flist:$OTHER_KEY:$fn\n" ) if($debug);
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
	
	foreach ( sort keys %ext_outfh ) {
		$ext = $_;
		$kind = $ext;
		$kind =~ s/\..*$//;
		$fh = $ext_outfh{ $ext };
		if ( -s "$resd/$HEAD_STR.$ext.$FLIST_STR" ) {
			printf( "RESULTS : %-16s : total line: ", "$ext" );
			system( "(echo /dev/null; cat $resd/$HEAD_STR.$ext.$FLIST_STR) |LANG=C xargs wc |sed '1d' |tee $resd/$HEAD_STR.$ext.wc |tail -1 |sed 's/total/$ext/' |tee -a $resd/$HEAD_STR.$kind._ktotal |sed 's/^ *//' |cut '-d ' -f1" );
		} else {
			printf( stderr "message : %-16s : no file\n", "$ext" ) if ( $warning );
		}
	}
	foreach $kind ( sort keys %ext_ptn ) {
		if ( -s "$resd/$HEAD_STR.$kind._ktotal" ) {
			printf( "TOTAL : %-16s : total line: ", "$kind" );
			system( "cat $resd/$HEAD_STR.$kind._ktotal |awk '{ a+=\$1; b+=\$2; c+=\$3; } END { print a,b,c; }' |tee $resd/$HEAD_STR.$kind._total |sed 's/^ *//' |cut '-d ' -f1" );
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
