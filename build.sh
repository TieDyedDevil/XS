#! /usr/bin/env sh

[ -d build ] || meson build
ninja-build -C build "$@"
