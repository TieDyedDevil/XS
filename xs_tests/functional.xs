run 'map produces expected values' {
	echo -n <={ map { |x| echo -n $x$x; result $x$x } a b c d e }
}
conds { match aabbccddeeaa bb cc dd ee }

run 'omap produces expected list' {
	result := <={ omap { |x| echo -n $x a$x } c d e }
	~ $#result 3 && echo $result
}
conds expect-success { match c ac d ad e ae }
