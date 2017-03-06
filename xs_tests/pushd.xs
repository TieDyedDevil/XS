run 'Pushd absolute' {
	orig = `pwd
	dir = _m29x8.
	mkdir $dir
	pushd $orig/$dir
	access -d . && ~ $orig/$dir `pwd
	popd
	access -d $dir && ~ $orig `pwd
}
conds expect-success

run 'Pushd relative' {
	orig = `pwd
	mkdir t
	pushd t
	access -d . && ~ $orig/t `pwd
	popd
	access -d t && ~ $orig `pwd
}
conds expect-success

run 'Pushd (no args)' {
	orig = `pwd
	mkdir t
	cd t
	pushd
	~ $orig/t `pwd
	popd
	~ $orig `pwd
}
conds expect-success
