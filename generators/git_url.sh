#! /usr/bin/env sh

[ -n "$MESON_SOURCE_ROOT" ] && cd $MESON_SOURCE_ROOT
FILE=$(basename $0 .sh).hxx
DATA=$(git remote get-url origin |
	sed 's/^/#define GIT_URL "/' | sed 's/$/"/')
echo $DATA | cmp -s - $FILE || echo "$DATA" > $FILE
