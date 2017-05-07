#! /usr/bin/env sh

../ylwrap ../parse.yxx y.tab.c parse.cxx y.tab.h `echo parse.cxx | sed -e s/cc$/hh/ -e s/cpp$/hpp/ -e s/cxx$/hxx/ -e s/c++$/h++/ -e s/c$/h/` y.output parse.output -- bison -y -d 

