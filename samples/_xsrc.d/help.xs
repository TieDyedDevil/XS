# Help functions
fn help {|*|
	.d 'Help for xs function'
	.a 'NAME'
	.a '-c [CATEGORY]'
	.c 'help'
	if {~ $* -c} {
		switch $#* (
		1 {vars -f | sed 's/{\.c [^}]*}/\n&\n/g' | grep -e '^{\.c' \
			| sed 's/''''/''/g' | sort | uniq}
		2 {vars -f|grep '{\.c '''''^$*(2) \
			| sed 's/{\.\(a\|c\|d\) [^}]*}/\n&\n/g' \
			| sed 's/^fn-[^ ]\+/\n&\n/g' \
			| grep -e '^\({\.\(a\|c\|\d\)\|fn-\)' \
			| sed 's/fn-\([^ ]\+\)/'^`.ab^'; \1'^`.an^'/g' \
			| sed 's/''''/''/g' | less -RFX}
		)
	} else if {~ $#* 1} {
		let (nm = $*(1); st) {
			st = <={vars -f|grep '^fn-'$nm'\b' \
				| sed 's/{\.\(a\|c\|d\) [^}]*}/\n&\n/g' \
				| grep -e '^{\.\(a\|c\|\d\)' \
				| sed 's/''''/''/g'}
			~ $^st '0 0 0 1 0' && {echo 'no help for' $nm; \
						whats $nm}
			~ $^st '0 1 0 1 0' && echo 'no function' $nm
		}
	} | less -RFX
}

## Online documentation
fn meson-help {
	.d 'meson documentation'
	.c 'help'
	web http://mesonbuild.com/
}
fn ninja-help {
	.d 'ninja documentation'
	.c 'help'
	web https://ninja-build.org/
}
