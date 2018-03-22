fn .usage {|*|
	# Display args help for named function.
	if {{~ $#* 1} && {!~ $* -*}} {help $* | grep '^a:'}
}

fn .pu {|*|
	# User ps: [FLAGS] [USER]
	let (flags) {
		while {~ $*(1) -*} {
			~ $*(1) -[fFcyM] && flags = $flags $*(1)
			* = $(2 ...)
		}
		ps -Hlj $flags -U^`{if {~ $#* 0} {echo $USER} else {echo $*}}
	}
}

fn .fbset {|*|
	# Set framebuffer size: x-pixels y-pixels
	if {~ $TERM linux} {fbset -a -g $* $* 32} else {echo 'not a vt'}
}

fn .d {|*|
	# Help tag: docstring
}
fn .a {|*|
	# Help tag: argstring
}
fn .c {|*|
	# Help tag: category
}
fn .r {|*|
	# Help tag: related
}

fn .web-query {|site path query|
	# Web lookup primitive.
	if {~ $#query 0} {
		web-browser $site
	} else {
		let (q) {
			q = `{echo $^query|sed 's/\+/%2B/g'|tr ' ' +}
			web-browser $site^$path^$q
		}
	}
}

fn .adapt-resolution {
	# Adapt X and GTK resolution to that of primary display.
	let (xrinfo = `{xrandr|grep '^[^ ]\+ connected primary'}; \
		size; w; xres; dpi) {
		if {~ $xrinfo ()} {throw error updres 'no primary display'}
		size = <={%argify `{echo $xrinfo|grep -o '[^ ]\+ x [^ ]\+mm' \
			|tr -d ' '}}
		(w _) = <= {~~ $size *mmx*mm}
		if {~ $w 0} {throw error updres 'can''t get resolution'}
		xres = `{echo $xrinfo|grep -o \
					'^[^ ]\+ connected primary [0-9]\+x'}
		xres = <={~~ $xres *x}
		dpi = <={%trunc `(25.4*$xres/$w)}
		%with-tempfile tf {
			printf 'Xft.dpi: %d'\n $dpi >$tf
			xrdb -merge $tf
		}
		%with-tempfile tf {
			printf 'Xft/DPI %d'\n `($dpi*1024) >$tf
			xsettingsd -c $tf >[2]/dev/null &
		}
		printf '%s @ %dppi'\n `{echo $xrinfo|cut -d' ' -f1} $dpi
	}
}
