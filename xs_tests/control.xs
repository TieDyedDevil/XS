
# This is not actually so simple, since
# x is shared (you'll get %closure if you print
# this)
run 'Simple until test' {
	let (x := a) {
		until { ~ $x b } {
			{ ~ $x b } && exit 1
			x := b
		}
		echo good
	}
}
conds expect-success { match good }

run 'Lexical return' {
    fn a ars { $ars }
    fn b { a {return}; exit 1 }
    b
    exit 0
}
conds expect-success
