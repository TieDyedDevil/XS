fn ff {|fname p t|
	let (fn-f1 = {|n| echo `($n+$p)}; \
	     fn-f2 = {|n| echo `($n*$t)}; \
	     g) {
		fn $fname {|s v|
			switch $s (
			\+ {f1 $v}
			\* {f2 $v}
                        \> {g = $v}
			\? {echo $g})
		}
		echo $fname
	}
}
