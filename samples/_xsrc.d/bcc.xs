for f /usr/share/bcc/tools/* {
	if {access -fx $f} {
		let (nm = `{basename $f}) {
			let (_d = 'bcc tool ('$nm^')'; \
			_a = '['$nm^'_OPTIONS]') {
				let (body = '{|*| %seq {.d '''$_d^'''}' \
					^' {.a '''$_a^'''} {.c ''priv''}' \
					^' {.c ''bcc''} {sudo '$f^' $*}}') {
					fn-$nm = $body
				}
			}
		}
	}
}

fn bcc-docs {
	.d 'Browse bcc example documentation'
	.c 'bcc'
	escape {|fn-done|
		while true {
			let (docs = /usr/share/bcc/tools/doc/*.txt; id) {
				{
					printf '%sbcc examples%s'\n \
						<=.%ah <=.%ahe
					for f $docs {echo `{basename $f .txt}} \
						|nl -w 3 -s ' '|column -x
				} |less -erFX
				printf 'doc# (. to quit)? '
				id = <=read
				~ $id . && done
				if {echo $id|grep -vq '^[0-9]\+$' \
						|| ~ $docs($id) ()} {
					echo '?'
				} else {
					less $docs($id)
					clear
				}
			}
		}
	}
}

fn bpftool {|*|
	.c 'priv'
	.c 'bcc'
	sudo /usr/sbin/bpftool $*
}
