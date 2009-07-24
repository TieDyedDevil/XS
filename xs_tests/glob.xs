run '* glob matches expected files' {
	touch t
	mkdir tx
	touch atx
	mkdir _.xty
	echo *t*
}
conds expect-success { match _.xty atx t tx }
run '? glob matches expected files' {
	touch aac
	touch a.c
	touch s_c
	touch a\?c
	mkdir rlc
	echo ??c
}
conds expect-success { match a.c a\?c aac rlc s_c }

