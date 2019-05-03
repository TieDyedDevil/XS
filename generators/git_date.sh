#! /usr/bin/env sh

[ -n "$MESON_SOURCE_ROOT" ] && cd $MESON_SOURCE_ROOT
FILE=$(basename $0 .sh).hxx
if [ -d ../.git ]; then
	DATA=$(git log -1 --date=short --pretty=tformat:%cd |
		sed 's/^/#define GIT_DATE "/' | sed 's/$/"/')
else
	DATA='#define GIT_DATE "-"'
fi
echo $DATA | cmp -s - $FILE || echo "$DATA" > $FILE
