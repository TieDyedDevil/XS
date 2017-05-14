run 'Simple alias operates' {
    alias debug echo TEST:
    debug hello world
}
conds {match 'TEST: hello world'}

run 'Self-referring alias does not recurse' {
    alias echo echo TEST2:
    echo bye-bye world
}
conds {match 'TEST2: bye-bye world'}

run 'Temporary alias disappears' {
    local (fn-echo) {
	alias echo echo -n ALIASED:
	echo 'TEST'
    }
    echo NOALIAS
}
conds {match 'ALIASED: TESTNOALIAS'}

run 'Alias print' {
    alias x ls
    echo $fn-x
}
conds expect-success
