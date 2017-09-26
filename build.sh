#! /usr/bin/env sh

if [ "$1" = '--clang' ]; then
	export CC=clang
	export CXX=clang++
	shift
	rm -rf build
elif [ "$1" = '--gcc' ]; then
	export CC=gcc
	export CXX=g++
	shift
	rm -rf build
fi
touch .build
[ -d build ] || meson build
ninja -C build "$@"
if [ ${#@} -eq 0 ] && [ $? -ne 0 ] && [ .build -nt build ]; then
	rm -rf build
	meson build
	ninja -C build "$@"
fi
rm -f .build
