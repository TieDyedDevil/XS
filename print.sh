#! /usr/bin/env sh

if which lpr-src >/dev/null 2>&1; then
	LPR=lpr-src
else
	LPR=lpr
fi

for f in *.[0-9]*; do
:#	man -l -Tpdf $f | lpr
done
$LPR meson.build build.sh [[:upper:]]* *.h *.hxx *.cxx initial.xs \
	`find generators samples tests xs-talk -type f -a \! -name \*.log` \
	print.sh
