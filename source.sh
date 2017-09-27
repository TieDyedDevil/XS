#! /usr/bin/env sh

if which lpr-src >/dev/null 2>&1; then
	LPR=lpr-src
else
	LPR=lpr
fi

FILES="\
	README INSTALL \
	`find doc src generators samples tests xs-talk man \
		-type f -a \! -name \*.log | grep -v badfuzz.xs` \
	meson.build build.sh source.sh \
"

if [ "$1" = "print" ]; then
	$LPR $FILES
elif [ "$1" = "man" ]; then
	[ $? -eq 0 ] && for f in man/*; do
		man -l -Tpdf $f | lpr
	done
elif [ -z "$1" -o "$1" = "count" ]; then
	wc -l $FILES|less -FX
else
	echo 'Huh?'
fi
