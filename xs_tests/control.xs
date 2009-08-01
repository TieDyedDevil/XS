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
