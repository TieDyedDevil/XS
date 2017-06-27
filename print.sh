#! /usr/bin/env sh

if which lpr-src >/dev/null 2>&1; then
	LPR=lpr-src
else
	LPR=lpr
fi

for f in *.[0-9]*; do
	man -l -Tpdf $f | lpr
done
$LPR meson.build [[:upper:]]* *.h *.hxx *.cxx `find -type f generators samples tests` print.sh
