run 'Pushd absolute' {
	orig = `pwd
	dir = _m29x8.
	mkdir $dir
	pushd $orig/$dir
	popd
	cd ..
	access -d $dir && ~ $orig `pwd
}
conds expect-success

run 'Pushd relative' {
	orig = `pwd
	mkdir t
	pushd t
	popd
	cd ..
	~ $orig `pwd
}
conds expect-success

run 'Pushd (no args)' {
	orig = `pwd
	mkdir t
	pushd t
	pushd
	cd t
	popd
	~ $orig `pwd && popd && ~ $orig/t `pwd
}
conds expect-success
