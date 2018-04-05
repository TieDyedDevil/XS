fn cs {|*|
	.d 'List compose sequences'
	.a '[-a]  # show all variations'
	.c 'unicode'
	.r 'u2o ulu'
	%with-read-lines <{grep -h '^<Multi_key>' ~/.XCompose \
				/usr/share/X11/locale/en_US.UTF-8/Compose | \
		grep -v -e '<dead' -e '<kana_' -e '<hebrew_' -e '<Arabic_' \
			-e '<Cyrillic_' -e '<Greek_' -e '<Ukrainian_' \
			-e '<KP_' -e '<ae>' -e '<AE>' -e '<ezh>' -e '<EZH>' \
			-e '<underbar>' -e '<.\?acute>' -e '<.\?tilde>' \
			-e '<.\?ring>' -e '<.\?diaeresis>' -e '<.\?grave>' \
			-e '<.\?cedilla>' -e '<.\?horn>' -e '<.\?circumflex>' \
			-e '<.\?breve>' -e '<.\?macron>' -e '<.\?acute>' \
			-e '<.\?caron>' -e '<.\?slash>' -e '<.\?oblique>' \
			-e '<U\([0-9A-Fa-f]\)\+>' \
		| grep -v -e '"   \b\(ascii[^ ]\+\|brace[^ ]\+\|at\|bar\|' \
			^'apostrophe\|numbersign\|bracket\(left\|right\)\) ' \
		| sed 's/^\(.\+ # \). . \(.\+\)$/\1\2/' \
		| if {~ $*(1) -a} cat else {uniq -f 4} \
	} {|*|
		kf = /usr/include/X11/keysymdef.h
		ksym = `{echo $*|sed 's|^[^:]\+:[[:space:]]\+"[^"]\+"' \
				^'[[:space:]]\+\([^ ]\+\).*$|\1|'}
		if {grep -q 'U[[:xdigit:]]\+\b' <{echo $ksym}} {
			echo $*
		} else {
			ksd = `{grep 'XK_'^$ksym^'\b' $kf}
			if {~ $#ksd 0} {
				echo $*
			} else {
				kuc = `{echo $ksd \
					|grep -o ' *U+[[:xdigit:]]\+ ' \
					|tr -d +|head -1}
				echo $*|sed 's|^\([^:]\+: \+"[^"]\+" \+\)' \
					^'[[:alpha:]]\+\(.*\)$|\1'^$kuc^'\2|'
			}
		}
	} | expand | awk -F: '{printf "%-48.48s:%s\n", ' \
				^'gensub(/^(.*) +$/, "\\1", "g", $1), ' \
				^'gensub(/ +/, " ", "g", $2)}' \
		| env LESSUTFBINFMT='*s?' less -iSFX
}
fn u16to8 {|*|
	.d 'Convert a UTF-16 file to UTF-8'
	.a 'FILE'
	.c 'unicode'
	%with-tempfile tf {
		iconv -f utf16 $* > $tf
		mv $tf $*
	}
}
fn u2o {|*|
	.d 'Unicode text to octal escapes'
	.a 'TEXT'
	.c 'unicode'
	.r 'cs ulu'
	if {~ $#* 0} {
		.usage u2o
	} else {
		echo -n $*|hexdump -b|grep -Eo '( [0-7]+)+'|tr ' ' \\\\
	}
}
fn ulu {|*|
	.d 'Unicode lookup'
	.a 'PATTERN'
	.c 'unicode'
	.r 'cs u2o'
	if {~ $#* 0} {
		.usage ulu
	} else {let (ud = /usr/share/unicode/ucd/UnicodeData.txt) {
		%with-read-lines <{egrep -i -o '^[0-9a-f]{4,};[^;]*' \
						^$*^'[^;]*;' $ud} {|l|
			let ((hex desc) = <={~~ $l *\;*\;}; uni) {
				!~ $desc \<control\> && {
					uni = <={%u $hex}
					printf %s\tU+%s\t%s\n $uni $hex $desc
				}
			}
		} | env LESSUTFBINFMT=*n!PRINT less -iFXS
	}}
}
