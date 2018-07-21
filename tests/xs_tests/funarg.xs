run 'Downward funarg' {
        echo <={{|f v| {$f $v}} {|x| result `($x*2)} 7}
}
conds { match '14' }

run 'Upward funarg' {
	fn counter-factory {
		let (ctr = 0) {
			let (fn-a = {|*|
				ctr = `($ctr+1)
				result $ctr
			} \
			) {
				result $fn-a
			}
		}
	}
	c1 = <=counter-factory
	c2 = <=counter-factory
	echo <=$c1 <=$c1 <=$c1 <=$c2 <=$c2 <=$c1
}
conds { match '1 2 3 1 2 4' }
