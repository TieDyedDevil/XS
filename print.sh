#! /usr/bin/env sh

if which lpr-src >/dev/null 2>&1; then
	LPR=lpr-src
else
	LPR=lpr
fi

$LPR README INSTALL \
	`find doc src generators samples tests xs-talk \
		-type f -a \! -name \*.log` \
	meson.build build.sh print.sh
[ $? -eq 0 ] && for f in man/*; do
	man -l -Tpdf $f | lpr
done
