
logdir="$1"
outdir="$2"

mkdir $outdir;

get_sorted_gclog_list() # logdir
{
	logdir="$1"

	(
	cd $logdir;
	for f in gc_pid*log*current
	do
		datetime=`echo $f |sed 's/.*_\(....-..-.._..-..-..\).*/\1/'`;
		echo $datetime
	done |sort |while read dt
	do
		org=gc_pid*${dt}*log*current
		echo "$logdir/$org"
	done
	)
}

cat `get_sorted_gclog_list $logdir` \
	|grep 'Full GC' |sort |tee $outdir/fullgc \
	|if `which perl >/dev/null 2>&1`; then \
		perl -e '
		BEGIN {
		print "DATE time sec GC_kind GC_reason PSYoungGen YoungBefore YoungAfte YoungMax ParOldGen OldBefore OldAfter OldMax AllBefore AllAfter AllMax Metaspace MetaBefore MetaAfter MetaMax GC_time secs Times user userTime sys sysTime real realTime secs\n";
		}
		while(<>){
			if ( /^(.*)\[Full GC \(([^\)]*)\) (.*)$/ ) {
				($head, $name ,$tail) = ($1, $2, $3);
				$head =~ s/T/ /;
				$head =~ s/: / /g;
				$name =~ s/ /_/g;
				$tail =~ s/[\[\]\(\),:=K]/ /g;
				$tail =~ s/->/ /g;
				print "$head Full_GC $name $tail\n";
			}
		}'; \
	else \
		cat;
	fi \
	|sed -e 's/Full GC \(([^\)]*)\)/FullGC "\1"/' \
		-e 's/\[//g' -e 's/\]/,/g' \
		-e 's/(/ /g' -e 's/)/ /g' \
		-e 's/,//g' \
		-e 's/: / /g' \
		-e 's/=/ /g' -e 's/->/ /g' \
	|tee $outdir/fullgc.fil \
	|sed -e 's/ [ ]*/,/g' \
	>$outdir/fullgc.fil.csv

###		-e 's/[0-9]T[0-9]/ /g' 
