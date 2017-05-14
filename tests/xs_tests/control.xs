
# This is not actually so simple, since
# x is shared (you'll get %closure if you print
# this)
run 'Simple until test' {
	let (x = a) {
		until { ~ $x b } {
			{ ~ $x b } && exit 1
			x = b
		}
		echo good
	}
}
conds expect-success { match good }

run 'Escape escapes' {
    escape { |e|
	$e
	exit 1
    }
    exit 0
}
conds expect-success

run 'Escape val' {
    echo <={escape { |e|
	$e 5
    }}
}
conds {match 5}

run 'Throw from escape' {
    escape { |e|
        throw error foo 'a b c'
    }
}
conds {match a b c}
