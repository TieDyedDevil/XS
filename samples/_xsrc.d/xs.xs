fn arrs {|*|
	.d 'List array variables'
	.a '[FILTER]'
	.c 'xs'
	vars | grep -a \377^'[^[]\+\[' | tr -d \377 | sort -V \
		| grep \^^$^*^.\* | column -c `{tput cols} \
		| less -iFX
}
fn libedit {|*|
	.d 'Edit library function'
	.a 'NAME'
	.c 'xs'
	.ensure-libloc
	let ((file line) = <={~~ <={%objget $libloc $*} *:*}) {
		!~ $file () && $EDITOR +$line $file
	}
}
fn objs {|*|
	.d 'List object variables'
	.a '[FILTER]'
	.c 'xs'
	let (tf = `mktemp) {
		vars | grep -a \377^objid: | tr -d \377 > $tf^02 # objs & names
		cat $tf^02 | grep -v '^objid:' | cut -d' ' -f3 > $tf^03 # keys
		grep -F -f $tf^03 $tf^02 > $tf^04 # objs and their names
		cat $tf^04 | sort -t: -k2 | split -d -n r/2 - $tf
			# 00: names; 01: objects
		cat $tf^01 | sed 's/^objid:[^ ]\+ = /{/' | sed 's/ \?obj$/}/' \
			> $tf^05 # objects rewritten as {key:value ...}
		paste $tf^00 $tf^05 | grep \^^$^*^.\* \
			| column -c `{tput cols} | less -iFXS
		rm -f $tf^??
	}
}
fn parse {|*|
	.d 'Parse an xs expression'
	.a '[EXPRESSION]'
	.c 'xs'
	if {~ $#* 0} {
		let (c = <={~~ <={%parse 'xs: ' '  : '} \{*\}}) {
			if {!~ $c ()} {xs -nxc $c}}} \
	else {xs -nxc $^*}
}
fn pp {|*|
	.d 'Prettyprint xs function'
	.a '[-c] NAME'
	.c 'xs'
	if {~ $#* 0} {
		.usage pp
	} else if {~ $*(1) -c} {
		%with-tempfile f {
			pp $*(2) > $f
			if {grep -qx 'not a function' $f} {
				cat $f
			} else {
				list -s xs $f
			}
		}
	} else catch {|e|
		echo 'not a function'
	} {
		%pprint $*
	} | less -iRFXS
}
fn uh {
	.d 'Undo history'
	.c 'xs'
	!~ $history () && {
		let (li = `{cat $history|wc -l}) {
			history -d $li >/dev/null
			history -d `($li-1)
		}
	}
}
%prewrap vars
fn vars {|*|
	.d 'List environment'
	.c 'xs'
	%_vars $* | less -RFXi
}
fn varss {|*|
	.d 'List environment w/o objects, arrays and xs utility vars'
	.c 'xs'
	%_vars $* | grep -av -e '^'\xff \
		-e '^''_[ns]@[0-9]\+'' ' \
		-e '^''_p[12abrt]@[0-9]\+'' ' \
		-e '^prompt ' \
		-e '^_o[abp] ' \
		-e '^libloc ' | less -RFXi
}
