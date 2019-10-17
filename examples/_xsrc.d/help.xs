# Help

fn apropos {|*|
	.d 'Find man pages by keyword'
	.a '[apropos_OPTIONS] KEYWORD...'
	.c 'help'
	.f 'wrap'
	%with-terminal apropos {/usr/bin/apropos -l $*|%wt-pager -S}
	true
}

fn clhs {
	.d 'Display Common Lisp HyperSpec'
	.c 'help'
	%with-terminal clhs {
		web -t file:///usr/local/share/doc/HyperSpec/Front/index_tx.htm
	}
}

fn clqr {
	.d 'Display Common Lisp quick reference'
	.c 'help'
	result %with-terminal
	zathura /usr/local/share/doc/clqr-letter-consec.pdf
}

fn cop {|*|
	.d 'Display C operator precedence and associativity'
	.c 'help'
	%with-terminal cop {
		{cat <<'EOF'
tokens			operator		class	prec	assoc
----------------------- ----------------------- ------- ------- -----------
names, literal		simple token		primary	16	N/A
a[k]			subscripting		postfix	16	left->right
f(...)			function call		postfix	16	left->right
.			direct selection	postfix	16	left->right
->			indirect selection	postfix	16	left->right
++ --			increment, decrement	postfix 16	left->right
(type name) {init}	compound literal (C99)	postfix	16	left->right
++ --			increment, decrement	prefix	15	right->left
sizeof			size			unary	15	right->left
~			bitwise not		unary	15	right->left
!			logical not		unary	15	right->left
- +			arith. negation, plus	unary	15	right->left
&			address of		unary	15	right->left
*			indirection		unary	15	right->left
(type name)		cast			unary	14	right->left
* / %			multiplicative		binary	13	left->right
+ -			additive		binary	12	left->right
<< >>			left and right shift	binary	11	left->right
< > <= >=		relational		binary	10	left->right
== !=			equality, inequality	binary	 9	left->right
&			bitwise and		binary	 8	left->right
^			bitwise xor		binary	 7	left->right
|			bitwise or		binary	 6	left->right
&&			logical and		binary	 5	left->right
||			logical or		binary	 4	left->right
? :			conditional		ternary	 3	right->left
= += -= *= /= %= <<= >>= &= ^= |=
			assignment		binary	 2	right->left
,			sequential evaluation	binary	 1	left->right

ref: "C: A Reference Manual", 5th ed, Harbison & Steele, 2002, Prentice Hall
EOF
		} | %wt-pager
	}
}

fn ecl-blog {
	.d 'Blog of Embeddable Common Lisp topics.'
	.c 'help'
	.r 'ecl-help'
	%with-terminal ecl-blog {
		web -t https://common-lisp.net/project/ecl/tag/quarterly.html
	}
}

fn ecl-help {
	.d 'Help for Embeddable Common Lisp.'
	.c 'help'
	.r 'ecl-blog'
	%with-terminal ecl-help {
		web -t file:///usr/share/doc/ecl/html/index.html
	}
}

fn help {|*|
	.d 'Help for xs function'
	.a 'NAME'
	.a '-c [CATEGORY]'
	.a '-l CATEGORY'
	.a '-h'
	.c 'help'
	if {~ $#* 0} {.usage help}
	%with-terminal help {let ( \
		fn-ext = {
			sed 's/{\.\(a\|c\|i\|d\|r\) [^}]*}/\n&\n/g'
		}; \
		fn-fmt = {
			sed 's/''''/''/g' | \
			sed 's/^{\.\(.\) ''\(.*\)''}$/\1: \2/' | \
			sed 's/''''/''/g' | \
			fold -s | awk -f <{cat <<'EOF'
/^(a|c|i|d|r|_): / {first=1;}
{if (first) {print; first=0;} else {print "    " $0}}
EOF
			}
		} \
		) {
		if {~ $*(1) -c && ~ $*(2) builtin} {
			-category-builtin
		} else if {~ $* -c} {
			switch $#* (
			1 {cat <{vars -f | ext | grep -e '^{\.c'} \
					<{echo 'c: builtin'} \
				| fmt | sort | uniq}
			2 {vars -f|grep '{\.c '''''^$*(2) \
				| ext | sed 's/^fn-[^ ]\+/\n&\n/g' \
				| grep -e '^\({\.\(a\|\d\|r\)\|fn-\)' \
				| sed 's/fn-\([^ ]\+\)/' \
					^'_: '^<=.%au^'\1'^<=.%an^'/g' \
				| fmt }
			)
		} else if {~ $*(1) -l} {
			if {~ $*(2) ()} {
				.usage help
			} else if {~ $*(2) builtin} {
				-list-builtin
			} else {
				vars -f|grep '{\.c '''''^$*(2) \
					| sed 's/^fn-\([^ ]\+\).*/\1/g' \
					| column
			}
		} else if {~ $* -h} {
			cat <<'EOF'
Legend
------
d: Description
a: Arguments
c: Category
r: Related
i: Informational
EOF
		} else if {~ $#* 1} {
			let (nm = $*(1); st) {
				st = <={vars -f|grep '^fn-'$nm'\s' | ext \
					| grep -e '^{\.\(a\|c\|i\|\d\|r\)' \
					| fmt}
				~ $^st '0 0 0 1 0' && {echo 'no help for' $nm; \
							whats $nm}
				~ $^st '0 1 0 1 0' && {
					-help-builtin $nm \
						|| echo 'no function' $nm
				}
			}
		}
	} | %wt-pager}
	true
}

fn lib {|*|
	.d 'List names of library functions'
	.a '-l  # sort by length, then name'
	.c 'help'
	%with-terminal lib {let (fn-sf) {
		if {~ $* -l} {fn-sf = %asort} else {fn-sf = cat}
		vars -f | cut -c4- | cut -d' ' -f1 | grep -E '^(%|\.)' \
			| grep -v -e %prompt -e '^%_' | sf \
			| column -c `{tput cols} | %wt-pager
	}}
	# Ideally we'd hide all of the xs hook functions; not only %prompt.
}

fn liba {|*|
	.d 'Library function names apropos.'
	.a 'MATCH'
	.c 'help'
	if {!~ $#* 1} {
		.usage liba
	} else {
		%with-terminal liba {
		for f `{vars -f|cut -c4-|cut -d' ' -f1|grep -E '^(%|\.)' \
				|grep -v -e %prompt -e '^%_'|grep -F $*} {
			printf '%s'\t $f
			catch {echo '?'} {%header-doc $f}|head -1
		} | column -s \t -t|%wt-pager -S}
	}
}

fn libdoc {
	.d 'List documentation for all library functions.'
	.c 'help'
	.ensure-libdoc
	%with-terminal libdoc {%wt-pager -rf ~/.cache/xslib/libdoc.$TERM}
}

fn libi {|*|
	.d 'Show information about a library function.'
	.a 'FUNCTION-NAME'
	.c 'help'
	%with-terminal libi {
	if {~ $#* 0} {
		.usage libi
	} else {
		.libi $*
	} | %wt-pager}
}

fn luc {|*|
	.d 'List user commands'
	.a '-l  # sort by length, then name'
	.a '-s  # list commands on system paths'
	.a '-w  # include wrapped commands'
	.c 'help'
	%with-terminal luc {
	let (al = <={%args $*}; fn-sf; fn-wf) {
		if {~ $al -l} {fn-sf = %asort} else {fn-sf = sort}
		if {~ $al -w} {fn-wf = cat} \
			else {fn-wf = {grep -v '{\.f [^}]*wrap[^}]*}'}}
		printf <=.%as^'@ ~/.xs*'^<=.%an^\n
		vars -f | wf \
			| grep -o '^fn-[^ ]\+' | cut -d- -f2- \
			| grep '^[a-z0-9]' | sf | column -c `{tput cols}
		printf <=.%as^'@ ~/bin'^<=.%an^\n
		find -L ~/bin -mindepth 1 -maxdepth 1 -type f -executable \
			| sf | xargs -n1 basename | column -c `{tput cols}
		if {~ $al -s} {
			printf <=.%as^'@ /usr/local/bin'^<=.%an^\n
			ls /usr/local/bin | sf | column -c `{tput cols}
			optbins = `{find /opt -type d -name bin}
			for d $optbins {
				printf <=.%as^'@ '^$d^<=.%an^\n
				ls $d | sf | column -c `{tput cols}
			}
		}
	} | %wt-pager -r }
}

fn luca {|*|
	.d 'User command names apropos.'
	.a 'MATCH'
	.c 'help'
	if {!~ $#* 1} {
		.usage luca
	} else {
		%with-terminal luca {
		for f `{vars -f|grep -o '^fn-[^ ]\+'|cut -d- -f2- \
					|grep '^[a-z0-9]'|grep -F -- $*} {
			printf '%s'\t $f
			var fn-^$f|sed 's/{\.d [^}]*}/\n&\n/g'|grep '^{\.d ' \
				|sed 's/''''/''/g' \
				|sed 's/^{\.\(.\) ''\(.*\)''}$/\1: \2/' \
				|sed 's/''''/''/g'|sed 's/^d: //'
		} | column -s \t -t|%wt-pager -S}
	}
}

fn man {|*|
	.d 'Display man page'
	.a 'man_OPTIONS'
	.c 'help'
	.f 'wrap'
	%with-terminal man {env COLUMNS=80 /usr/bin/man $*}
}

## Online documentation

fn 0mq-help {
	.d '0MQ documentation'
	.c 'help'
	web http://zeromq.org/intro:read-the-manual
}

fn boost-help {
	.d 'Boost documentation'
	.c 'help'
	web http://boost.org/doc/libs/
}

fn czmq-help {
	.d 'CZMQ documentation (0MQ)'
	.c 'help'
	web http://czmq.zeromq.org/
}

fn fedora-help {
	.d 'Fedora documentation'
	.c 'help'
	web https://docs.fedoraproject.org/
}

fn git-help {
	.d 'git documentation'
	.c 'help'
	web https://git-scm.com/doc
}

fn gsoap-help {
	.d 'gSOAP documentation'
	.c 'help'
	web file:///usr/share/doc/gsoap-doc/index.html
}

fn imagemagick-help {
	.d 'ImageMagick documentation'
	.c 'help'
	web file:///usr/share/doc/ImageMagick-6/index.html
}

fn kernel-doc {|*|
	.d 'Search Linux kernel docs'
	.a '[QUERY]'
	.c 'web'
	let (kv = v^`{uname -r|sed 's/^\([^.]\+\.[^.]\+\).*$/\1/'}) {
		.web-query https://kernel.org/doc/html/$kv^/ search.html\?q= $*
	}
}

fn llvm-help {
	.d 'LLVM documentation'
	.c 'help'
	web file:///usr/share/doc/llvm/html/index.html
}

fn meson-help {
	.d 'meson documentation'
	.c 'help'
	.r 'ninja-help'
	web http://mesonbuild.com/
}

fn ninja-help {
	.d 'ninja documentation'
	.c 'help'
	.r 'meson-help'
	web https://ninja-build.org/
}

fn python2-doc {|*|
	.d 'Search Python 2 docs'
	.a '[QUERY]'
	.c 'web'
	.web-query https://docs.python.org/2/ search.html\?q= $*
}

fn python3-doc {|*|
	.d 'Search Python 3 docs'
	.a '[QUERY]'
	.c 'web'
	.web-query https://docs.python.org/3/ search.html\?q= $*
}

fn rfc {|*|
	.d 'IETF RFCs'
	.a '-l|-k KEYWORD...|RFC_NUMBER...'
	.c 'help'
	if {~ $#* 0} {
		.usage rfc
	} else if {~ $* -l && ~ $#* 1} {
		web -t https://www.rfc-editor.org/rfc-index.txt
	} else if {~ $*(1) -k && $#* :gt 1} {
		web -t https://www.rfc-editor.org/search/ \
			^rfc_search_detail.php?title=^<={%flatten + $*(2 ...)}
	} else {
		for n $* {
			~ $n [0-9][0-9][0-9][0-9] || \
				throw error rfc $n^' not 4 digits'
		}
		web -t https://www.rfc-editor.org/rfc/rfc^$*^.txt
	}
}

fn tcl-tk-help {
	.d 'Tcl/Tk documentation'
	.c 'help'
	web -t file:///usr/share/doc/tcl-html/index.html
}

fn tcl-tk-wiki {
	.d 'Tcl/Tk wiki'
	.c 'help'
	web https://wiki.tcl-lang.org/
}

fn valgrind-help {
	.d 'valgrind documentation'
	.c 'help'
	web http://valgrind.org/
}

fn xml-rpc-help {
	.d 'XML-RPC documentation'
	.c 'help'
	web http://xmlrpc-c.sourceforge.net/doc/
}

fn xml-rpc-howto {
	.d 'XML-RPC HOWTO'
	.c 'help'
	web https://www.tldp.org/HOWTO/text/XML-RPC-HOWTO
}

fn zyre-help {
	.d 'Zyre documentation (0MQ)'
	.c 'help'
	web https://github.com/zeromq/zyre/blob/master/README.md
}
