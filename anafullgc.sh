ALL_LOG="./log/*"

cat $ALL_LOG |grep 'Full GC' |sort |tee fullgc \
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
		-e 's/[0-9]T[0-9]/ /g' \
		-e 's/=/ /g' -e 's/->/ /g' \
	|tee fullgc.fil \
	|sed -e 's/ [ ]*/,/g' \
	>fullgc.fil.csv
