run 'fsplit' {
	let (x := <={%fsplit ':./' 'a/b.d:cc:c::/'}) {
		echo $#x $^x
	}
}
conds { match '7 a b d cc c' }

run 'split' {
	let (x := <={%split ':./' 'a.b/c.d//efg'}) {
		echo $#x $^x
	}
}
conds { match '5 a b c d efg' }
