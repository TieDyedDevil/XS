#! /usr/bin/env sh

TESTFILE=`mktemp`
find . -name '*.xs'|xargs cat >>$TESTFILE
zzuf -O copy -s 1:100000 -r 0.0001:0.0050 -R '\000' -vic ./build/xs -p -n $TESTFILE
rm -f $TESTFILE
