#! /usr/bin/env sh

git remote get-url origin | sed 's/^/#define GIT_URL "/' | sed 's/$/"/'
