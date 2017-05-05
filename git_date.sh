#! /usr/bin/env sh

git log -1 --date=short --pretty=tformat:%cd | sed 's/^/#define GIT_DATE "/' | sed 's/$/"/'
