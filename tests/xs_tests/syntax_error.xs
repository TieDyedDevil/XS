run 'XS let precise error' {
	$XS -c 'let>[2=1] *'
}
conds expect-failure { match let } { match syntax error }

run 'Syntax error on bad let' {
	$XS -ic 'let>[2=1] *'
}
conds { match syntax error }
