#! /usr/bin/env sh

rm -rf buildscan
mkdir buildscan
scan-build meson buildscan
cd buildscan
scan-build --view ninja
