#! /usr/bin/env sh

[ -d build ] || meson build
ninja -C build "$@"
