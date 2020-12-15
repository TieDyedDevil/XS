#! /usr/bin/env sh

[ -n "$MESON_SOURCE_ROOT" ] && cd $MESON_SOURCE_ROOT
FILE=$(basename $0 .sh).hxx
COMPILER=$(${CC:-cc} --version|head -1)
DATA="#define BUILDINFO \"$USER @ `hostname`; `date --rfc-3339=s`; $COMPILER\""
echo "$DATA" | cmp -s - $FILE || echo "$DATA" > $FILE
