fn %advise {|name thunk|
	# Insert a thunk at the beginning of a function
	let (f = `` \n {var fn-$name}; c) {
		if {{echo $f|grep -wqv $thunk} && {echo $f|grep -q '{.*}'}} {
			c = `` \n {echo -- $f|sed 's/= ''\({\(|[^|]\+|\)\?' \
				^'%seq \)\(.*}\)/= ''\1'^$thunk^' \3/'}
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
			rm -f $name
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

fn %asort {
	# Sort by length, then by name.
	%with-read-lines /dev/stdin {|line|
		let (len = <={$&len $line}) {
			printf %06d%s\n $len $line
		}
	} | sort | cut -c7-
}

fn %read-char {
	# Read one character from stdin.
	let (c) {
		unwind-protect {
			stty -icanon
			c = `{dd bs=1 count=1 >[2]/dev/null}
		} {
			stty icanon
		}
		result $c
	}
}

fn %menu {|*|
	# Present a menu. The argument list is a header followed by
	# a list of <key, title, action> tuples. Keystrokes are
	# processed immediately. The menu remains active until an
	# action invokes `break`.
	let (hdr; l; mt; ma; key; title; action; c; a; none = <=%gensym) {
		hdr = $*(1); * = $*(2 ...)
		ma = <=%mkobj
		while {!~ $* ()} {
			(key title action) = $*(1 2 3); * = $*(4 ...)
			mt = $mt $key $title
			%objset $ma $key $action
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
					a = <={%objget $ma $c $none}
					printf \n
					if {!~ $a $none} {
						$a
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
		stty -echo
		$cmd
	} {
		stty echo
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
	escape {|fn-quit| let (pass = 0; file = <={%objget $libloc $fn-name}) {
		~ $file () && throw error %header-doc 'not in library'
		%with-read-lines $file {|l|
			if {~ $pass 1} {
				if {~ $l \t\#*} {
					printf %s `` '' {echo $l|cut -c4-}
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
	let (expanded = `{eval ls $path >[2]/dev/null}) {
		$thunk $expanded
	}
}
