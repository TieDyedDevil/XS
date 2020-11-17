fn %with-tempfile {|name body|
	# Bind a temporary file to name while evaluating body.
	local ($name = `mktemp) {
		unwind-protect {
			$body
		} {
			rm -f $($name)
		}
	}
}

fn %with-suffixed-tempfile {|name suffix body|
	# Bind a temporary file to name while evaluating body.
	# The file is named using the given suffix.
	local ($name = `{mktemp -t XXXXXXXXXX^$suffix}) {
		unwind-protect {
			$body
		} {
			rm -f $($name)
		}
	}
}

fn %with-tempdir {|name body|
	# Bind a temporary directory to name while evaluating body.
	local ($name = `{mktemp -d}) {
		unwind-protect {
			$body
		} {
			rm -rf $($name)
		}
	}
}

fn %with-read-lines {|file body|
	# Run body with each line from file.
	# Body must be a lambda; its argument is bound to the line content.
	<$file let (__l = <=read) {
		while {!~ $__l ()} {
			$body $__l
			__l = <=read
		}
	}
}

fn %with-read-chars {|line body|
	# Run body with each character from line.
	# Body must be a lambda; its argument is bound to the next character.
	let (i = 0; lc = <={%fsplit '' $line}) {
		let (ll = $#lc; __c) {
			let (fn-nextc = {
				i = `($i+1)
				if {$i :le $ll} {
					result <={__c = $lc($i)}
				} else {
					result <={__c = ()}
				}}) {
				while {!~ <=nextc ()} {
					$body $__c
				}
			}
		}
	}
}

fn %read-char {
	# Read one UTF-8 character from tty.
	let (c; oc; r) {
		unwind-protect {
			</dev/tty $&tctl raw
			c = <={$&getc </dev/tty}
			oc = `{%ord $c}
			if {$oc :le 127} {
				r = $c
			} else if {$oc :ge 248} {
				throw error %read-char 'Invalid UTF-8'
			} else if {$oc :ge 240} {
				r = $c^<={$&getc </dev/tty}
				r = $c^<={$&getc </dev/tty}
				r = $c^<={$&getc </dev/tty}
			} else if {$oc :ge 224} {
				r = $c^<={$&getc </dev/tty}
				r = $c^<={$&getc </dev/tty}
			} else if {$oc :ge 112} {
				r = $c^<={$&getc </dev/tty}
			}
		} {
			</dev/tty $&tctl canon
		}
		result $r
	}
}

fn %append-path {|*|
	# Append given directory if not already present on $PATH.
	~ $PATH *:$* *:$*:* || PATH = $PATH:$*
}

fn %prepend-path {|*|
	# Prepend given directory if not already present on $PATH.
	~ $PATH $*:* *:$*:* || PATH = $*:$PATH
}

fn %outdated {|target sources|
	# True if the target file is not newer than all source files.
	result <={!map {|f| test $target -nt $f} $sources}
}

fn %wait-file-deleted {|path|
	# Ensure that path is an ordinary file, then wait for its deletion.
	access -f $path || ~ <={access -1 $path} () || throw error \
		%wait-file-deleted $path^' is not an ordinary file'
	touch $path
	inotifywait -e delete_self $path >/dev/null >[2=1]
}

fn %split-xform-join {|xform mult infile tmpbase outfile|
	# Transform infile to outfile using multiple processes.
	# Process count is number of CPU cores times mult, capped at a
	# total of the lesser of 100 or the number of lines in infile.
	# The xform function is of the form {|srcfile dstfile| ...}.
	# The split files are named on tmpbase; this is normally `tmpfile .
	let (cores; np; fl; sn; segs; waitpids) {
		cores = `{grep '^cpu cores' /proc/cpuinfo|head -1|cut -d: -f2}
		np = `($cores*$mult)
		$np :gt 100 && np = 100
		fl = `{head -$np $infile|wc -l}
		if {!~ $fl 0} {
			$np :gt $fl && np = $fl
			sn = <={omap {|n| printf %02d `($n-1)} <={%range 1-$np}}
			fork {cd /tmp; split -d -a 2 -n l/$np $infile seg$pid}
			segs = seg$pid^$sn
			waitpids =
			catch {|e|
				kill $waitpids
				throw $e
			} {
				for sf $segs {
					{xs -c {$xform /tmp/$sf \
						$tmpbase^.$sf} &} >[2]/dev/null
					waitpids = $waitpids $apid
				}
				for p $waitpids {wait $p}
			}
			cat $tmpbase^.$segs >$tmpbase
			mv $tmpbase $outfile
		} else {
			touch $tmpbase
			mv $tmpbase $outfile
		}
		rm -f /tmp/$segs $tmpfile^.$segs
	}
}

fn %safe-wild {|path thunk|
	# Given a quoted wildcard path, evaluate thunk with a handler to ignore
	# a 'no such ...' error and the expanded path passed as an argument.
	# Multiple wildcard paths may be separated using colon (:).
	let (expanded = `` \n {eval /usr/bin/ls <={%split : $path} \
							>[2]/dev/null}) {
		$thunk $expanded
	}
}

fn %have {|pgm|
	# Return true when pgm is on $PATH.
	which $pgm > /dev/null >[2=1]
}

fn %ext {|*|
	# Extract extension from path.
	let (x = $*) {
		while {~ $x *.*} {
			(_ x) = <= {~~ $x *.*}
		}
		result $x
	}
}

fn %view-with-header {|count file title|
	# Preserve the first count lines while viewing file.
	# Display title in the pager's prompt.
	unwind-protect {
		tput cup 0 0
		tput ed
		tput csr $count `{tput lines}
		tput cup 0 0
		let (ts = ''; tl = `($count+1)) {
			!~ $title () && ts = `` '' {printf '[%s] ' $title}
			env TERM=dumb less -dfiSXF -j$tl \
				-P$ts^'%lt-%lb?L/%L ?e(END)' \
				<{cat $file|tee >{head -$count >/dev/tty} \
					|tail -n +$tl}
		}
	} {
		tput sc
		tput csr 0 `{tput lines}
		tput rc
	}
}

fn %redir-file-or-stdout {|file|
	# Redirect stdout to file, if given.
	if {!~ $file ()} {cat >$file} else {cat >/dev/stdout}
}

fn %redir-file-or-stderr {|file|
	# Redirect stderr to file, if given.
	if {!~ $file ()} {cat >[2]$file} else {cat >[2]/dev/stderr}
}

fn %absolute-path {|path|
	# Return an absolute path.
	if {~ $path /*} {
		result $path
	} else if {access -- $path} {
		result `{cd `{dirname $path}; pwd}^/$path
	} else {
		throw error %absolute-path 'path?'
	}
}
