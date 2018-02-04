# Help functions
fn help {|*|
	.d 'Help for xs function'
	.a 'NAME'
	.a '-c [CATEGORY]'
	.c 'help'
	if {~ $#* 0} {.usage help}
	let ( \
		fn-ext = {
			sed 's/{\.\(a\|c\|d\|r\) [^}]*}/\n&\n/g'
		}; \
		fn-fmt = {
			sed 's/''''/''/g' | \
			sed 's/^{\.\(.\) ''\(.*\)''}$/\1: \2/'
		} \
		) {
		if {~ $* -c} {
			switch $#* (
			1 {vars -f | ext | grep -e '^{\.c' | fmt | sort | uniq}
			2 {vars -f|grep '{\.c '''''^$*(2) \
				| ext | sed 's/^fn-[^ ]\+/\n&\n/g' \
				| grep -e '^\({\.\(a\|c\|\d\|r\)\|fn-\)' \
				| sed 's/fn-\([^ ]\+\)/'^`.as^'; \1'^`.an^'/g' \
				| fmt }
			)
		} else if {~ $#* 1} {
			let (nm = $*(1); st) {
				st = <={vars -f|grep '^fn-'$nm'\b' | ext \
					| grep -e '^{\.\(a\|c\|\d\|r\)' | fmt}
				~ $^st '0 0 0 1 0' && {echo 'no help for' $nm; \
							whats $nm}
				~ $^st '0 1 0 1 0' && echo 'no function' $nm
			}
		} | less -irFX
	}
}

## Online documentation
fn boost-help {
	.d 'Boost documentation'
	.c 'help'
	web http://boost.org/doc/libs/
}
fn git-help {
	.d 'git documentation'
	.c 'help'
	web https://git-scm.com/doc
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
fn valgrind-help {
	.d 'valgrind documentation'
	.c 'help'
	web http://valgrind.org/
}

# Local web documents
fn ffl-help {
	.d 'Forth Foundation Library documentation'
	.c 'help'
	web -t /usr/share/doc/gforth-ffl/html/index.html
}
