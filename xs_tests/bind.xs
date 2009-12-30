run 'Let without assign' {
	x = 3
	echo -n $x
	x = 5
	let (x y) {
		echo -n a$x $y
		x = 4
	}
	echo -n $x
}
conds { match '35' }
