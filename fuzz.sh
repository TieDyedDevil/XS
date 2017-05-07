#! /usr/bin/env sh

TESTFILE=`mktemp`
cat ./initial.xs >$TESTFILE
find ./xs_tests -name '*.xs'|xargs cat >>$TESTFILE
zzuf -O copy -s 1:10000 -r 0.001:0.050 -vic ./build/xs -p -n $TESTFILE
rm $TESTFILE
