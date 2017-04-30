#! /usr/bin/env sh

git describe --dirty --always --tags | sed 's/^/#define GIT_INFO "git: /' | sed 's/$/"/'
