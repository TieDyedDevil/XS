run 'Eval echo' {
	eval echo _test
}
conds expect-success { match _test }
