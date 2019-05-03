#! /usr/bin/env sh

[ -n "$MESON_SOURCE_ROOT" ] && cd $MESON_SOURCE_ROOT
FILE=$(basename $0 .sh).hxx
if [ -d ../.git ]; then
	DATA=$(git remote get-url origin | sed 's/\.git$//' |
		sed 's/^/#define GIT_URL "/' | sed 's/$/"/')
else
	DATA='#define GIT_URL "-"'
fi
echo $DATA | cmp -s - $FILE || echo "$DATA" > $FILE
