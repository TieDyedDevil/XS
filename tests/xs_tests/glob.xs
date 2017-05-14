run 'solitary * matches all non-. files' {
	touch .t
	touch a.t
	touch x
	mkdir yc
	echo *
}
conds expect-success { match a.t x yc }

run '* glob matches expected files' {
	touch t
	mkdir tx
	touch atx
	mkdir _.xty
	touch bt
	echo *t*
}
conds expect-success { match _.xty atx bt t tx }
run '? glob matches expected files' {
	touch aac
	touch a.c
	touch s_c
	touch a\?c
	mkdir rlc
	echo ??c
}
conds expect-success { match a.c a\?c aac rlc s_c }

run '*/* glob matches expected files' {
	 mkdir a
	 mkdir b
	 mkdir _.x
	 touch a/b
	 touch b/c
	 touch _.x/lsdkfj
	 echo */*
}
conds expect-success { match _.x/lsdkfj a/b b/c  }
