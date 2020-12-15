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
	local un=${1:-$USER}
	local td=$(eval "echo ~$un")
	if [[ $td == ~* ]]; then
		echo "No user $1"
		exit 1
	fi
	if [ ! -w $td ]; then
		echo "$USER cannot write $td"
		exit 1
	fi
	if [ -f $td/.xsrc ]; then
		printf "Overwrite [y/N]? "
		read REPLY
		if [ "$REPLY" != y ]; then
			echo "Cancelled"
			exit 1
		fi
	fi
	install -o $un -m 755 -d $td/.local/run
	install -o $un -m 644 examples/_xsrc $td/.xsrc
	install -o $un -m 644 examples/_xsin $td/.xsin
	install -o $un -m 755 -d $td/.xsrc.d
	install -o $un -m 644 examples/_xsrc.d/* $td/.xsrc.d
	install -o $un -m 755 -d $td/.xslib.d
	install -o $un -m 644 examples/_xslib.d/* $td/.xslib.d
}

examples_help () {
	PGM=`basename $0`
	cat <<EOD
usage: $PGM ACTION
where ACTION is one of:
  diff			Compare files in ./examples vs ~/.
  snapshot		Capture changed files for distribution.
  install [user]	Copy files from ./examples to ~user/.
EOD
}

case "$1" in
	diff) examples_diff ;;
	snapshot) examples_snapshot ;;
	install) examples_install $2 ;;
	*) examples_help ;;
esac
