# Help functions
fn apropos {|*|
	.d 'Find man pages by keyword'
	.a '[apropos_OPTIONS] KEYWORD...'
	.c 'help'
	/usr/bin/apropos -l $*|less -iFXS
}
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
				| sed 's/fn-\([^ ]\+\)/' \
					^<=.%as^'; \1'^<=.%an^'/g' \
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
fn lib {|*|
	.d 'List names of library functions'
	.a '-l  # sort by length, then name'
	.c 'help'
	let (fn-sf) {
		if {~ $* -l} {fn-sf = %asort} else {fn-sf = cat}
		vars -f | cut -c4- | cut -d' ' -f1 | grep -E '^(%|\.)' \
			| grep -v -e %prompt -e '^%_' | sf \
			| column -c `{tput cols} | less -iFX
	}
	# Ideally we'd hide all of the xs hook functions; not only %prompt.
}
fn libdoc {
	.d 'List documentation for all library functions.'
	.c 'help'
	{
		%with-tempfile tf {
			for f `{for e <={%split ' ' $$libloc} {
				echo $e|cut -d: -f1} |head -n-1|sort} {
					echo $f >>$tf
			}
			%split-filter-join \
				{|infile outfile|
					%with-read-lines $infile {|f|
						printf \n----\n%s%s%s\n\n \
							<=.%au $f <=.%aue
						catch {} {libi $f}
					} >>$outfile
				} \
				1 \
				$tf \
				`mktemp \
				$tf
			printf '%sLibrary functions%s'\n <=.%ah <=.%ahe
			cat $tf
		}
	}|less -RXi
}
fn libi {|*|
	.d 'Show information about a library function.'
	.a 'FUNCTION-NAME'
	.c 'help'
	if {~ $#* 0} {
		.usage libi
	} else {
		{~ <={result $#(fn-$*)} 0} && {
			throw error libi 'not a function'
		}
		{~ <={%objget $libloc $*} ()} && {
			throw error libi 'not in library'
		}
		%header-doc $* | nl -w2 -s': '
		printf \n'arglist : %s'\n'location: %s'\n \
			<={%argify `` \n {%arglist $*}} <={%objget $libloc $*}
	}
}
fn luc {|*|
	.d 'List user commands'
	.a '-l  # sort by length, then name'
	.a '-s  # list commands on system paths'
	.c 'help'
	%with-terminal { \
	let (al = <={%args $*}; fn-sf) {
		if {~ $al -l} {fn-sf = %asort} else {fn-sf = sort}
		printf <=.%as^'@ ~/.xs*'^<=.%an^\n
		vars -f | grep -o '^fn-[^ ]\+' | cut -d- -f2- | grep '^[a-z]' \
			| sf | column -c `{tput cols}
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
	} | less -irFX }
}
fn man {|*|
	.d 'Display man page'
	.a 'man_OPTIONS'
	.c 'help'
	%with-terminal {env COLUMNS=80 /usr/bin/man $*}
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
fn clips-user {
	.d 'CLIPS user guide'
	.c 'help'
	web /usr/share/doc/clips-doc/html/ug.htm
}
fn clips-basic-programming {
	.d 'CLIPS basic programming guide'
	.c 'help'
	web /usr/share/doc/clips-doc/html/bpg.htm
}
fn clips-advanced-programming {
	.d 'CLIPS advanced programming guide'
	.c 'help'
	web /usr/share/doc/clips-doc/html/bpg.htm
}
fn clips-interfaces {
	.d 'CLIPS interfaces guide'
	.c 'help'
	web /usr/share/doc/clips-doc/html/ig.htm
}
fn ffl-help {
	.d 'Forth Foundation Library documentation'
	.c 'help'
	web -t /usr/share/doc/gforth-ffl/html/index.html
}
fn fsl-help {
	.d 'Forth Scientific Library algorithm list'
	.c 'help'
	%with-terminal list /usr/share/gforth/site-forth/fsl/status.txt
}
