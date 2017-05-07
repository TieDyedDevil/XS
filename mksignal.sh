#! /usr/bin/env sh

INCS=$(cpp -E /usr/include/signal.h | grep include |
	sed 's/^[^"]*"//' | sed 's/".*$//' | sort | uniq)
../mksignal $INCS >$1
