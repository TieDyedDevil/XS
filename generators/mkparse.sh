#! /usr/bin/env sh

bison -y -d ../src/parse.yxx
mv y.tab.c parse.cxx
mv y.tab.h parse.hxx
