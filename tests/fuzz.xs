#! /usr/bin/env xs

XS = ./build/xs
TESTFILE = `mktemp
LOGFILE = ./tests/fuzz.log
BADFILE = ./tests/badfuzz.xs
find . -name '*.xs'|xargs cat >>$TESTFILE
rm -f $BADFILE
unwind-protect {
	fork {zzuf -A -O copy -U 1.0 -s 1:100000 -r 0.0001:0.0050 \
		-R '\000' -qvic $XS $TESTFILE >[2]$LOGFILE}
} {
	if {tail -1 $LOGFILE|grep -q 'maximum crash count'} {
		parms = `{tail -2 $LOGFILE|grep -o '\[[^]]\+\]' \
			|tr -d '[]'|tr , ' '|sed 's/\([rs]\)/-\1/g'}
		zzuf $parms <$TESTFILE >$BADFILE
		reset
		cat <<EOF
Fuzzing failed. The offending code is in $BADFILE

Also, you'll probably need to ^C to reset your shell's input.

EOF
	} else {
		echo 'No failures'
	}
}
