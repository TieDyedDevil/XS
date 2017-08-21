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
	# Given the output of $args followed by \& and a list of option/
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
		let (l = <={%args $a}; words; extra) {
			while {!~ $l ()} {
				(optopt optval l) = $l
				if {~ $extra(1) --} {extra = $extra $optval} \
				else switch $optval (
					_ {words = $words $optval}
					-- {extra = $optopt}
					$cases
				)
			}
			result $words $extra
		}
	}
}

fn %with-quit {|*|
	# Run command with q key bound to send SIGINTR.
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
	local ($name = `mktemp) {
		unwind-protect {
			$body
		} {
			rm -f $name
		}
	}
}

fn %aset {|n i v|
	# Emulate indexed assignment.
	$n[$i] = $v
}

fn %aref {|n i|
	# Emulate indexed retrieval.
	result $($n[$i])
}
