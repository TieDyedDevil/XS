#! /usr/bin/env sh

[ -d build ] || env CXX=clang++ meson build
ninja -C build "$@"
