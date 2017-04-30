#! /usr/bin/env sh

git describe --abbrev=7 --dirty --always --tags | sed 's/^/#define GIT_INFO "/' | sed 's/$/"/'
