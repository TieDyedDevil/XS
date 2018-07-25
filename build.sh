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
elif [ "$1" = '--afl-clang' ]; then
	export CC=afl-clang
	export CXX=afl-clang++
	shift
	rm -rf build
elif [ "$1" = '--afl-gcc' ]; then
	export CC=afl-gcc
	export CXX=afl-g++
	shift
	rm -rf build
fi
touch .build
[ -d build ] || meson build
meson configure -Db_lto=true --strip build
ninja -C build "$@"
if [ $? -ne 0 ] && [ .build -nt build/.stamp ] \
		&& [ "$*" != 'fuzz' ] && [ "$*" != 'check' ]; then
	rm -rf build
	meson build
	ninja -C build "$@"
fi
rm -f .build
