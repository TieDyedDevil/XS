#! /usr/bin/env sh

[ -n "$MESON_SOURCE_ROOT" ] && cd $MESON_SOURCE_ROOT
FILE=$(basename $0 .sh).hxx
if [ -d ../.git ]; then
	DATA=$(git describe --dirty --always --tags |
		sed 's/^/#define GIT_HASH "/' | sed 's/$/"/')
else
	DATA='#define GIT_HASH "-"'
fi
echo $DATA | cmp -s - $FILE || echo "$DATA" > $FILE
