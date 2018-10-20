#! /usr/bin/env sh

meson_opts='-Db_lto=true --strip'

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
[ -d build ] || meson $meson_opts build
if [ $? -ne 0 ]; then false; else ninja -C build "$@"; fi
if [ $? -ne 0 ] && [ .build -nt build/.stamp ] \
		&& [ "$*" != 'fuzz' ] && [ "$*" != 'check' ]; then
	echo Recreating build/
	rm -rf build
	meson $meson_opts build
	if [ $? -ne 0 ]; then false; else ninja -C build "$@"; fi
fi
rm -f .build
