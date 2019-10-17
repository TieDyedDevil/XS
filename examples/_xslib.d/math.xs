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

fn %rational {|float dlimit|
	# Convert float to rational, limiting magnitude of denominator.
	# Second value is the error of rational approximation.
	let (rat = `{python >[2]/dev/null << EOF
from fractions import Fraction
print(Fraction.from_float($float).limit_denominator($dlimit))
EOF
	}) {
		result $rat `{eval 'echo `(('^$rat^'.0)-'^$float^')'}
	}
}

fn %abs {|a|
	# Return abs(a).
	if {$a :gt 0} {result $a} else {result `(0-$a)}
}

fn %gcd {|a b|
	# Return gcd(a, b).
	let (al = $a; bl = $b) {
		while {!~ $bl 0} {
			t = `($al%$bl)
			al = $bl
			bl = $t
		}
		~ $al -* && al = `(0-$al)
		result $al
	}
}

fn %lcm {|a b|
	# Return lcm(a, b).
	~ $a 0 && result $b
	~ $b 0 && result $a
	!~ $a 0 && !~ $b 0 && let (g = <={%gcd $a $b}) {
		result <={%abs `($a*$b/$g)}
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

fn %dBv2lin {|dBv|
	# Convert dBv to a voltage ratio.
	result `{calc '10**('^$dBv^'/20)'}
}

fn %lin2dBv {|lin|
	# Convert a voltage ratio to dBv.
	result `{calc '20*log10('^$lin^')'}
}

fn %numparts {|num|
	if {~ $num .*} {result 0 <={~~ $num .*}} \
	else if {~ $num *.*} {result <={~~ $num *.*}} \
	else result $num 0
}

fn %intpart {|num|
	let ((i f) = <={%numparts $num}) {result $i}
}

fn %fracpart {|num|
	let ((i f) = <={%numparts $num}) {result $f}
}
