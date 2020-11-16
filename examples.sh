#! /usr/bin/env sh

examples_diff () {
	{
	diff -q examples/_xsrc ~/.xsrc
	diff -q examples/_xsin ~/.xsin
	diff -q examples/_xsrc.d ~/.xsrc.d
	diff -q examples/_xslib.d ~/.xslib.d
	} | grep -v '^Only in ' | less -FX
}

examples_snapshot () {
	cp ~/.xsrc examples/_xsrc
	cp ~/.xsin examples/_xsin
	rsync -rvq --existing ~/.xsrc.d/* examples/_xsrc.d/
	rsync -rvq --existing ~/.xslib.d/* examples/_xslib.d/
	date '+%F' > examples/SNAPSHOT_DATE
}

examples_install () {
	cp examples/_xsrc ~/.xsrc
	cp examples/_xsin ~/.xsin
	mkdir -p ~/.xsrc.d
	cp examples/_xsrc.d/* ~/.xsrc.d
	mkdir -p ~/.xslib.d
	cp examples/_xslib.d/* ~/.xslib.d
}

examples_help () {
	PGM=`basename $0`
	cat <<EOD
usage: $PGM ACTION
where ACTION is one of:
  diff		Compare files in ./examples vs ~/.
  snapshot	Capture changed files for distribution.
  install	Copy files from ./examples to ~/.
EOD
}

case "$1" in
	diff) examples_diff ;;
	snapshot) examples_snapshot ;;
	install) examples_install ;;
	*) examples_help ;;
esac
