#! /usr/bin/env sh

touch .build
[ -d build ] || meson build
ninja -C build "$@"
if [ $? -ne 0 ] && [ .build -nt build ]; then
	rm -rf build
	meson build
	ninja -C build "$@"
fi
rm -f .build
