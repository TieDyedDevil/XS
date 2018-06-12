fn %advise {|name thunk|
	# Insert a thunk at the beginning of a function
	let (f = `` \n {var fn-$name}; c) {
		if {{echo $f|grep -wqv $thunk} && {echo $f|grep -q '{.*}'}} {
			c = `` \n {echo -- $f|sed 's/= ''\(%closure([^)]*)' \
				^'{\)\(.*}''\)$/= ''\1%seq '^$thunk^' {\2}/'}
			if {$c :eq $f} {
				c = `` \n {echo -- $f|sed 's/= ''\({\(|[^|]\+|\)\?' \
					^'%seq \)\(.*}\)/= ''\1'^$thunk^' \3/'}
			}
			if {$c :eq $f} {
				c = `` \n {echo -- $f|sed 's/= ''\({\(|[^|]' \
					^'\+|\)\?\)\(.*}\)/= ''\1 %seq ' \
					^$thunk^' {\3}/'}
			}
			if {$c :eq $f} {
				c = `` \n {echo -- $f|sed 's/= ''\(.*\)''$' \
					^'/= ''{%seq '^$thunk^' {\1}}''/'}
			}
			fn-$name = `` \n {echo -- $c|sed 's/fn-[^ ]\+ = ' \
				^'''\(.\+\)''/\1/'|sed 's/''''/''/g'}
		}
	}
}

fn %unadvise {|name thunk|
	# Remove a thunk from a function.
	let (f = $(fn-$name)) {
		if {{echo $f|grep -wq $thunk} && {echo $f|grep -q '{.*}'}} {
			fn $name `` \n {echo $f|sed 's/'^$thunk^'//'}
		}
	}
}

fn %prewrap {|name|
	# Capture the original function as %_NAME.
	# Use this to wrap a function.
	~ $(fn-%_^$name) () && fn-%_^$name = $(fn-$name)
}

fn %max {|*|
	# Return the largest of a list.
	let (f; (m r) = $*) {
		while {!~ $r ()} {
			(f r) = $r
			{$f :gt $m} && {m = $f}
		}
		result $m
	}
}

fn %min {|*|
	# Return the smallest of a list.
	let (f; (m r) = $*) {
		while {!~ $r ()} {
			(f r) = $r
			{$f :lt $m} && {m = $f}
		}
		result $m
	}
}

fn %range {|*|
	# Given a comma-separated list of counting numbers and ranges, where
	# a range is delimited with -, return a sorted list of integers.
	# The order of a range's endpoints does not matter.
	let (f; r = $*; l) {
		while {!~ $r ()} {
			if {~ $r *,*} {(f r) = <={~~ $r *,*}} else {(f r) = $r}
			if {~ $f *-*} {
				(a b) = <={~~ $f *-*}
				{$a :gt $b} && {(a b) = $b $a}
				let (n = $a; s = `($b + 1)) {
					while {!~ $n $s} {
						l = $l $n
						n = `($n + 1)
					}
				}
			} else {
				l = $l $f
			}
		}
		result `{echo $l|tr ' ' \n|sort -n}
	}
}

fn %list {|*|
	# Given a comma-separated list of tokens, return a list of tokens.
	let (f; r = $*; l) {
		while {!~ $r ()} {
			if {~ $r *,*} {(f r) = <={~~ $r *,*}} else {(f r) = $r}
			l = $l $f
		}
		result $l
	}
}

fn %args {|*|
	# Given a list of command-line arguments where the list contains N
	# elements, return a 2N-element list where each pair of elements
	# corresponds to one element of the argument. The first element of
	# each pair is always an option flag; the second is always a non-
	# option argument. The absence of a flag or argument is denoted by
	# _ in the result list. Tokens following a -- option are all treated
	# as arguments, even in the case where a token begins with -.
	let (r = $*; l) {
		while {!~ $r ()} {
			let (f; m = '_') {
				(f r) = $r
				if {~ $f --} {
					l = $l $f $m
					while {!~ $r ()} {
						(f r) = $r
						l = $l $m $f
					}
				} else if {~ $f -*} {
					let ((a b) = $r) {
						if {~ $a -*} {
							l = $l $f $m
						} else {
							{~ $a ()} && a = $m
							l = $l $f $a
							r = $b
						}
					}
				} else {
					l = $l $m $f
				}
			}
		}
		result $l
	}
}

fn %parse-args {|*|
	# Given the output of %args followed by \& and a list of option/
	# thunk pairs to be used for processing options, process the
	# options and a return a list of the non-option words optionally
	# followed by -- and following words. Within the option thunks,
	# the option and its value are denoted $optopt and $optval.
	let (a) {
		let (l = $*) {
			{escape {|fn-break| while {!~ $l ()} {
				(o v l) = $l
				{~ $o \&} && {l = $v $l; break}
				a = $a $o $v
			}}}
			cases = $l
		}
		let (l = $a; words; extra) {
			while {!~ $l ()} {
				(optopt optval l) = $l
				if {~ $extra(1) --} {extra = $extra $optval} \
				else switch $optopt (
					_ {words = $words $optval}
					-- {extra = $optopt}
					$cases
					{throw error %parse-args \
						'opt? '^$optopt}
				)
			}
			result $words $extra
		}
	}
}

fn %argify {|*|
	# Always return a one-element list.
	if {~ $* ()} {result ''} else {result `` '' {echo -n $*}}
}

fn %with-quit {|*|
	# Run command with q key bound to send SIGINT.
	stty intr q
	unwind-protect {
		$*
	} {
		stty intr \^C
	}
}

fn %without-cursor {|*|
	# Run command with terminal cursor hidden.
	.ci
	unwind-protect {
		$*
	} {
		.cn
	}
}

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
	local ($name = `{mktemp --suffix=$suffix}) {
		unwind-protect {
			$body
		} {
			rm -f $($name)
		}
	}
}

fn %aset {|name index value|
	# Emulate indexed assignment.
	\xff^$name[$index] = $value
}

fn %asetm {|name value indices|
	# Emulate multidimensional indexed assignment.
	let (n_ = \xff^$name; i_) {
		for i_ $indices {n_ = $n_^[$i_]}
		eval \{ $n_ \= $value \}
	}
}

fn %aref {|name index|
	# Emulate indexed retrieval.
	result $(\xff^$name[$index])
}

fn %arefm {|name indices|
	# Emulate multidimensional indexed retrieval.
	let (n_ = \xff^$name; i_) {
		for i_ $indices {n_ = $n_^[$i_]}
		result $($n_)
	}
}

let (g = 0) {
	fn %gensym {
	# Generate a "unique" name.
		let (n = \xff\xff^`{printf G%04u $g}) {
			g = `($g+1)
			result $n
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

fn %pprint {|fn-name|
	# Prettyprint named function.
	~ $(fn-$fn-name) () && {throw error %pprint 'not a function'}
	printf fn\ %s $fn-name
	let (depth = 1; q = 0; i = 0; lc) {
		let ( \
			fn-wrap = {
				!~ $lc ' ' && printf ' '
				printf %c\n '\'
				for i `{seq `($depth*4)} {printf ' '}
			} \
			) {
			%with-read-chars $(fn-$fn-name) {|c|
				~ $c '''' && {q = `(($q+1)%2)}
				~ $q 0 && switch $c (
				'%'	{~ $i 0 && {wrap; depth = `($depth+1)}}
				'{'	{wrap; depth = `($depth+1)}
				'}'	{depth = `($depth-1)}
				'^'	{wrap}
				)
				i = 1
				printf %c $c
				lc = $c
			}
		}
	}
	printf \n
}

fn %id {|*|
	# Without an arg, return a five-element list:
	#   name version date hash repository-url
	# With an arg, return the index'th item(s).
	let (info = xs <={~~ <=$&version 'xs '*' (git: '*'; '*' @ '*')'}) {
		if {~ $#* 0} {
			result $info
		} else {
			result $info($*)
		}
	}
}

fn %mkobj {
	# Create an object; return its name.
	let (nm = go; go = go) {
		while {!~ $($nm) ()} {nm = \xff^objid:^<=$&random}
		$nm = obj
		result $nm
	}
}

fn %rmobj {|objname|
	# Destroy a named object.
	eval $objname^' ='
}

fn .objcheck {|objname|
	# Throw an error if objname does not name an object.
	if {{~ $objname ()} || {!~ $($objname) obj *\ obj}} {
		throw error object 'Not an object: '^$objname
	}
}

fn %objset {|objname key value|
	# Set an object field.
	.objcheck $objname
	%objunset $objname $key
	$objname = $key:$value $($objname)
}

fn %objunset {|objname key|
	# Remove an object field.
	.objcheck $objname
	let (ov = $($objname); rv) {
		for kv $ov {
			{!~ $kv $key:*} && {rv = $rv $kv}
		}
		$objname = $rv
	}
}

fn %objget {|objname key default|
	# Get an object field.
	.objcheck $objname
	let (v = <={~~ $($objname) $key:*}) {
		if {!~ $v ()} {result $v} else {result $default}
	}
}

fn %obj-isempty {|objname|
	# True if object has no fields.
	.objcheck $objname
	result <={!~ $($objname) *:*}
}

fn %objreset {|objname|
	# Remove all fields from an object.
	.objcheck $objname
	$objname = obj
}

fn %objpersist {|objname path|
	# Persist named object to path.
	.objcheck $objname
	echo $objname $($objname) >$path
}

fn %objrestore {|path|
	# Restore object from path and return object's ID.
	let (t = `` ' ' {cat $path}) {
		eval $t(1) \= $t(2 ...)
		result $t(1)
	}
}

fn %mkdict {|*|
	# Make a dictionary from a list of key/value pairs.
	let (d = <=%mkobj) {
		while {!~ $* ()} {
			(k v) = $*(1 2)
			* = $*(3 ...)
			%objset $d $k $v
		}
		result $d
	}
}

fn %with-object {|lambda|
	# Execute lamba, passing a fresh object.
	# The object is disposed upon leaving the lambda.
	let (__o = <=%mkobj) {
		unwind-protect {
			$lambda $__o
		} {
			$__o =
		}
	}
}

fn %with-dict {|lambda pairs|
	# Execute lambda, passing a fresh object initialized with pairs.
	# The object is disposed upon leaving the lambda.
	let (__o = <={%mkdict $pairs}) {
		unwind-protect {
			$lambda $__o
		} {
			$__o =
		}
	}
}

fn %asort {
	# Sort by length, then by name.
	%with-read-lines /dev/stdin {|line|
		let (len = <={$&len $line}) {
			printf %06d%s\n $len $line
		}
	} | sort | cut -c7-
}

fn %read-char {
	# Read one UTF-8 character from tty.
	let (c; oc; r) {
		unwind-protect {
			stty -F /dev/tty -icanon
			c = `` '' {dd if=/dev/tty bs=1 count=1 >[2]/dev/null}
			oc = `{%ord $c}
			if {$oc :le 127} {
				r = $c
			} else if {$oc :ge 248} {
				throw error %read-char 'Invalid UTF-8'
			} else if {$oc :ge 240} {
				r = $c ^ `{dd if=/dev/tty bs=1 count=3 \
						>[2]/dev/null}
			} else if {$oc :ge 224} {
				r = $c ^ `{dd if=/dev/tty bs=1 count=2 \
						>[2]/dev/null}
			} else if {$oc :ge 112} {
				r = $c ^ `{dd if=/dev/tty bs=1 count=1 \
						>[2]/dev/null}
			}
		} {
			stty -F /dev/tty icanon
		}
		result $r
	}
}

fn %menu {|*|
	# Present a menu. The argument list is a header followed by
	# a list of <key, title, action, disposition> tuples.
	# The action does not have access to lexical variables.
	# Disposition is either C (continue after action) or B (break
	# after action). Keystrokes are processed immediately.
	let (hdr; l; mt; ma; key; title; action; cb; c; a; none = <=%gensym) {
		hdr = $*(1); * = $*(2 ...)
		ma = <=%mkobj
		while {!~ $* ()} {
			(key title action cb) = $*(1 2 3 4); * = $*(5 ...)
			mt = $mt $key $title
			%objset $ma $key $action $cb
		}
		escape {|fn-break|
			while true {
				{!~ <={$&len $hdr} 0} && printf %s\n $hdr
				l = $mt
				while {!~ $l ()} {
					(key title) = $l(1 2); l = $l(3 ...)
					printf %c\ %s\n $key $title
				}
				escape {|fn-redisplay| while true {
					printf \?\ 
					c = <=%read-char
					{~ $c ()} && redisplay
					{~ $c \x04} && break
					(a cb) = <={%objget $ma $c $none}
					printf \n
					if {!~ $a $none} {
						$a
						~ $cb B && break
					} else {
						printf What\?\n
					}
				}}
				printf \n
			}
		}
		printf \n
	}
}

fn %list-menu {|*|
	# Present a menu. The argument list is a header, a lambda,
	# and a list of items. The lambda is applied to the selected
	# item.
	let ((hdr action) = $*(1 2); l = $*(3 ...); i; n) {
		i = 0
		for n $l {
			i = `($i+1)
			echo $i $n
			%aset s $i $n
		}
		escape {|fn-break|
			while true {
				printf '#? '
				n = <=read
				~ $n () && {printf \n; break}
				if {echo $n|grep -q '^[[:digit:]]\+$'} {
					i = <={%aref s $n}
					{!~ $i ()} && {$action $i; break}
				}
			}
		}
	}
}

fn %without-echo {|cmd|
	# Disable terminal echo while evaluating cmd.
	unwind-protect {
		stty -F /dev/tty -echo
		$cmd
	} {
		stty -F /dev/tty echo
	}
}

fn %with-bracketed-paste-mode {|cmd|
	# Enable terminal bracketed-paste mode while evaluating cmd.
	unwind-protect {
		printf \e'[?2004h'
		$cmd
	} {
		printf \e'[?2004l'
	}
}

fn %header-doc {|fn-name|
	# Print a functions's header documentation.
	# If present, print .d (description) and .a
	# (argument) lines.
	.ensure-libloc
	escape {|fn-quit| let (pass = 0; file = <={%objget $libloc $fn-name}) {
		~ $file () && throw error %header-doc 'not in library'
		(file _) = <={~~ $file *:*}
		%with-read-lines $file {|l|
			if {~ $pass 1} {
				if {~ $l \t\#*} {
					printf %s `` '' {echo $l|cut -c4-}
				} else if {~ $l \t.d* \t.a*} {
					printf %s `` '' {echo $l}
				} else {
					quit
				}
			}
			{~ $l *fn\ $fn-name^*} && {pass = 1}
		}
	}}
}

fn %arglist {|fn-name|
	# Print a function's argument list.
	let ((_ args _) = <={~~ $(fn-$fn-name) *\|*\|*}) {
		echo $args
	}
}

fn %safe-wild {|path thunk|
	# Given a quoted wildcard path, evaluate thunk with a handler to ignore
	# a 'no such ...' error and the expanded path passed as an argument.
	# Multiple wildcard paths may be separated using colon (:).
	let (expanded = `` \n {eval ls <={%split : $path} >[2]/dev/null}) {
		$thunk $expanded
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

fn %cfn {|test name thunk|
	# When test is true, define function.
	if $test {fn $name $thunk}
}

fn %have {|pgm|
	# Return true when pgm is on $PATH.
	which $pgm > /dev/null >[2=1]
}

fn %running {|*|
	# Return true when process is running.
	# Accepts pgrep options.
	pgrep -c $* >/dev/null
}

fn %only-X {
	# Throw an error if not running under X.
	~ $DISPLAY () && throw error %only-X 'Only under X'
}

fn %only-vt {
	# Throw an error if not running on a virtual terminal.
	~ `consoletype vt || throw error %only-vt 'Only in vt'
}

fn %strip-csi {
	# Filter strips ANSI CSI sequences.
	sed 's/\x1B\[[0-9;]*[a-zA-Z]//g'
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

fn %prefixes {|word min|
	# Return all prefixes of word.
	# If specified, min is length of shortest prefix.
	let (r; i = $min; l = <={$&len $word}) {
		~ $i () && i = 1
		while {$i :le $l} {
			r = $r `{echo $word|cut -c 1-$i}
			i = `($i+1)
		}
		result $r
	}
}

fn %trunc {|float|
	# Truncate a floating point number.
	let ((i f) = <={~~ $float *.*}) {result $i}
}

fn %round {|float|
	# Round a floating point number.
	# ½ rounds up.
	result <={%trunc `($float+.5)}
}

fn %spawn-avoiding-duplication {|objname args body|
	# Spawn body (a lambda) in the background, passing args.
	# If this instance of %spawn-avoiding-reentry is currently
	# executing body, avoid reentry. The objname must be the
	# name of an object created by %mkobj and allocated in an
	# enclosing scope.
	#
	# WARNING: While suitable for cases where it's desirable
	# to not run a body already in execution (e.g. to avoid
	# spawning two instances of the same long-running task),
	# %spawn-avoiding-duplication must *not* be used where an
	# occasional reentry will cause your program to fail.
	#
	# Example:
	# let (lockobj = <=%mkobj) {
	#     for i <={%range 1-9} {
	#         echo invoke $i
	#         %spawn-avoiding-duplication $lockobj 7 {|*|
	#             sleep $*  # we're busy...
	#             echo executed with arg $*
	#         }
	#         echo return $i
	#         sleep 1
	#     }
	# }
	if <={%objget $objname ready true} {
		%objset $objname ready false
		unwind-protect {
			$body $args
		} {
			if {! <={%objget $objname ready}} {$body $args}
			%objset $objname ready true
		} &
	}
}

fn %as-bool {|*|
	# Convert args to boolean.
	# (), '' and 0 are true; everything else is false.
	if {~ $* ()} {
		result true
	} else {
		let (r) {
			for v $* {
				if {result $v} {
					r = $r true
				} else {
					r = $r false
				}
			}
			result $r
		}
	}
}

fn %withrgb {|bghex fghex text|
	# Display text with Truecolor bg/fg colors.
	# Hex values are prefixed with `#` and have six digits.
	let (fn-hrgb2d = {|hex|
			map {|*| echo $*|awk --non-decimal-data \
				'{printf "%d ", $1}'} \
				`{%rgbhex $hex|sed -E 's/\#(..)(..)(..)/' \
					^'0x\1 0x\2 0x\3/'}}) { \
		printf \e'[48;2;%03d;%03d;%03dm'\e'[38;2;%03d;%03d;%03dm%s' \
			`{hrgb2d $bghex} `{hrgb2d $fghex} $^text
	}
}

fn %rgbhex {|color|
	# Emit a hex color code given the same or an X11 color name
	if {~ `{echo $color|cut -c1} '#'} {
		printf %s $color
	} else {
		printf '#%02x%02x%02x' \
			`{grep -wi '\W'^$^color^'$' /usr/share/X11/rgb.txt \
				|cut -c1-11}
	}
}

fn %preserving-title {|cmd|
	# Run a command, preserving the title of the focused window.
	if {!~ $DISPLAY ()} {
		let (__t = `{xdotool getwindowfocus getwindowname}) {
			unwind-protect {
				$cmd
			} {
				title $__t
			}
		}
	} else {
		$cmd
	}
}

fn %u {|cp|
	# Return the UTF-8 character denoted by its codepoint.
	eval result '\u'''$cp''''
}

fn %with-application-keypad {|cmd|
	# Run command with keypad application keys.
	printf \e\=
	unwind-protect {$cmd} {printf \e\>}
}

fn %active-displays-info {
	# Print <name>\t<geometry> for each active display; one per line.
	xrandr|grep '^[^ ]\+ connected'|grep -o '^[^ ]\+.*[0-9]\+x[0-9]\+' \
			^'+[0-9]\++[0-9]\+'|sed 's/ primary//' \
		|cut -d' ' -f1,3|tr ' ' \t
}

fn %ord {|*|
	# Print decimal ordinal values of bytes in given word(s).
	hexdump -v -e '1/1 " %d"' <{echo -n $*}
}

fn %with-terminal {|cmd|
	# Run command, spawning a terminal if necessary.
	local (DISPLAY = :0) {
		if {tty -s} {$cmd} else {st xs -c {$cmd}}
	}
}

fn %with-tabbed-terminal {|cmd|
	# Run command, spawning a tabbed terminal if necessary.
	local (DISPLAY = :0) {
		if {tty -s} {$cmd} else {tabbed -c -r 2 st -w '' xs -c {$cmd}}
	}
}

fn %wait-file-deleted {|path|
	# Ensure that path is an ordinary file, then wait for its deletion.
	access -f $path || ~ <={access -1 $path} () || throw error \
		%wait-file-deleted $path^' is not an ordinary file'
	touch $path
	inotifywait -e delete_self $path >/dev/null >[2=1]
}

fn %confirm {|dflt msg|
	# Query user for confirmation with default given as y or n.
	# Return true when confirmed.
	let (yes = <={if {~ $dflt y} {result Y} else {result y}}; \
	no = <={if {~ $dflt n} {result N} else {result n}}) {
		let (prompt = ' ['$yes'/'$no']? ') {
			escape {|fn-return| while true {
				printf %s%s <={%argify $msg} $prompt
				c = <=read
				~ $c '' && c = $dflt
				~ $c () && c = $dflt
				switch $c (
				y {return <=true}
				n {return <=false}
				{}
				)
			}}
		}
	}
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
					xs -c {$xform /tmp/$sf $tmpbase^.$sf} &
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

fn %outdated {|target sources|
	# True if the target file is not newer than all source files.
	result <={!map {|f| test $target -nt $f} $sources}
}

fn %ignore-error {|body|
	# Ignore error exception thrown by body.
	catch {|e| !~ $e(1) error && throw $e} {$body}
}

fn %X-screen-size {
	# Return X screen size.
	%only-X
	result `{xrandr|grep -o 'current [0-9]\+ x [0-9]\+'|cut -d' ' -f2,4}
}

fn %X-with-cursor {|name body|
	# Run body with named X cursor.
	%only-X
	unwind-protect {
		xsetroot -cursor_name $name
		$body
	} {
		xsetroot -cursor_name X_cursor
	}
}

fn %is-mobile {
	# Return true if system chassis is "mobile".
	let (chassis = `{cat /sys/devices/virtual/dmi/id/chassis_type}) {
		if {{$chassis :ge 8} && {$chassis :le 16}} {true} else {false}
	}
}

fn %multiple-displays {
	# Return true if multiple displays are connected.
	%only-X
	if {`{xrandr|grep -w connected|wc -l} :gt 1} {true} else {false}
}
