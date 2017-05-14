run switch_normal {
	switch _test9 (
	    _t		{ exit 1 }
	    _test9	{ echo success }
	    _lahk 	{ exit 2 }
	    w9ek	{ exit 3 }
	    9f		{ exit 4 }
	    _test9 	{ exit 5 }
	)
}
conds expect-success {match 'success'}

run switch_default {
	switch __x_ (
	    s		{ exit 1 }
	    { echo success }
	)
}
conds expect-success {match 'success'}
