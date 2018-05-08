fn cr2lf {|*|
	.d 'Convert a file having CR line endings'
	.a 'FILE'
	.c 'file'
	let (f = `mktemp) {
		cat $* | tr \r \n > $f
		mv $f $*
	}
}
fn crlf2lf {|*|
	.d 'Convert a file having CRLF line endings'
	.a 'FILE'
	.c 'file'
	let (f = `mktemp) {
		cat $* | tr -d \r > $f
		mv $f $*
	}
}
fn hd {
	.d 'Simple hex dump'
	.c 'file'
	hexdump -e '"%07.7_Ax  (%_Ad)\n"' \
		-e '"%07.7_ax  " 8/1 "%02x " "  " 8/1 "%02x " "\n"'
}
fn import-abook {|*|
	.d 'Import vcard to abook'
	.a 'VCARD_FILE'
	.c 'file'
	if {~ $#* 0} {
		.usage import-abook
	} else {
		access -- ~/.abook/addressbook \
			&& mv ~/.abook/addressbook ~/.abook/addressbook-OLD
		abook --convert --infile $* --informat vcard \
			--outformat abook --outfile ~/.abook/addressbook
		chmod 600 ~/.abook/addressbook
	}
}
fn list {|*|
	.d 'List file with syntax highlighting'
	.a '[-s SYNTAX|-f] FILE'
	.a '-l  # list SYNTAX names'
	.c 'file'
	if {~ $#* 0} {
		.usage list
	} else if {~ $* -l} {
		ls ~/.config/vis/lexers/*.lua \
			/usr/local/share/vis/lexers/*.lua \
			| grep -v lexer\\\.lua \
			| xargs -I\{\} basename \{\} | sed s/\.lua\$// \
			| sort | uniq | column -c `{tput cols} | less -iFX
	} else {
		let (syn; \
			lpath = ~/.config/vis/lexers \
				/usr/local/share/vis/lexers; \
			fallback = false; \
			fn-canon = {|ext|
				%with-dict {|d|
					result <={%objget $d $ext $ext}
				} (1 man 3 man 5 man 7 man ascii text
					iso-8859 text c ansi_c sh bash
					dash bash posix bash bourne-again bash
					patch diff md markdown fs forth
					4th forth adb ada ads ada gpr ada
					rs rust rst rest p pascal py python
					js javascript es rc hs haskell)} \
			) {
			if {~ $*(1) -s} {
				syn = $*(2)
				* = $*(3 ...)
			} else {
				if {~ $(1) -f} {
					fallback = true
					* = $*(2 ...)
				}
				{~ $#* 1 && access -- $* && !access -d -- $*} \
					|| {throw error list 'file?'}
				syn = `{echo $*|sed 's/^.*\.\([^.]\+\)$/\1/'}
				syn = <={canon $syn}
				{~ $syn () || \
				 !~ <={access -f $lpath/^$syn^.lua} 0} && {
					syn = `{file -L $* | cut -d: -f2 \
						| awk '
/^ a .*\/env [^ ]+ script/ {print $3; next}
/^ a .*\/[^ ]+ (-[^ ]+ )?script/ {
	print gensub(/^ [^ ]+ .+\/([^ ]+) .*$/, "\\1", 1); next
}
// {print $1}
' \
						| tr '[[:upper:]]' '[[:lower:]]'}
					syn = <={canon $syn}
					~ <={access -f $lpath/^$syn^.lua} 0 \
						|| syn = ()
				}
				if {~ $syn ()} {
					if $fallback {syn = null} \
					else {throw error list \
						'specify -s SYNTAX or -f'}
				}
			}
			access -- $* || {throw error list 'file?'}
			if {file $*|grep -q 'CR line terminators'} {
				vis-highlight $syn <{cat $*|tr \r \n}
			} else {
				vis-highlight $syn $*
			} | nl >[2]/dev/null | less -iRFXS
		}
	}
}
fn lpman {|man|
	.d 'Print a man page'
	.a 'PAGE'
	.c 'file'
	if {~ $#man 0} {
		.usage lpman
	} else {
		env MANWIDTH=80 man $man | sed 's/^.*/    &/' \
			| lpr -o page-top=60 -o page-bottom=60 \
				-o page-left=60 -o lpi=8 -o cpi=12
	}
}
fn lpmd {|md|
	.d 'Print a markdown file'
	.a 'FILE'
	.c 'file'
	if {~ $#md 0} {
		.usage lpmd
	} else {
		markdown $md | w3m -T text/html -cols 80 | sed 's/^.*/    &/' \
			| lpr -o page-top=60 -o page-bottom=60 \
				-o page-left=60 -o lpi=8 -o cpi=12
	}
}
fn mdv {|*|
	.d 'Markdown file viewer'
	.a 'MARKDOWN_FILE'
	.c 'file'
	if {!~ $#* 1} {
		.usage mdv
	} else if {!access -f $*} {
		echo 'file?'
	} else {
		markdown -f fencedcode $* | w3m -X -T text/html -no-mouse \
			-no-proxy -o confirm_qq=0 -o document_root=`pwd
	}
}
fn qpdec {|*|
	.d 'Decode quoted-printable text file'
	.a 'FILE'
	.c 'file'
	cat $*|perl -MMIME::QuotedPrint=decode_qp -e 'print decode_qp join"",<>'
}
fn qpenc {|*|
	.d 'Encode text file as quoted-printable'
	.a 'FILE'
	.c 'file'
	cat $*|perl -MMIME::QuotedPrint=encode_qp -e 'print encode_qp join"",<>'
}
fn unzipd {|*|
	.d 'Unzip into a directory named after the archive'
	.a 'ZIP_FILE'
	.c 'file'
	let (d = `` \n {basename $* .zip}) {
		mkdir -p $d
		mv $* $d
		unwind-protect {
			cd $d
			unzip $* || true
		} {
			cd ..
		}
	}
}
fn vman {|*|
	.d 'View man page'
	.a '[man_OPTS] PAGE'
	.c 'file'
	%only-X
	if {~ $#* 0} {
		.usage vman
	} else {
		%with-suffixed-tempfile f .ps {let (embed) {
			!~ $XEMBED () && embed = -e $XEMBED
			man -Tps $* >$f && /usr/bin/zathura $embed $f \
							>/dev/null >[2=1]
		}}
	}
}
fn zathura {|*|
	.d 'Document viewer'
	.c 'file'
	local (embed) {
		!~ $XEMBED () && embed = -e $XEMBED
		setsid /usr/bin/zathura $embed $* >/dev/null >[2=1] &
	}
}
