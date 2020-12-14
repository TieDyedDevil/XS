#! /usr/bin/env sh

[ -n "$MESON_SOURCE_ROOT" ] && cd $MESON_SOURCE_ROOT
FILE=$(basename $0 .sh).hxx
DATA="#define BUILDINFO \"$USER @ `hostname`; `date`\""
echo "$DATA" | cmp -s - $FILE || echo "$DATA" > $FILE
