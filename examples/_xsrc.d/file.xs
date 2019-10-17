fn abrowse {|*|
	.d 'Browse archive file'
	.a 'FILE'
	.c 'file'
	if {!~ $#* 1} {
		.usage abrowse
	} else {
		%with-tempdir mp {
			archivemount -o readonly $* $mp && unwind-protect {
				noice $mp
			} {
				fusermount -u $mp
			}
		}
	}
}

fn cr2lf {|*|
	.d 'Convert a file having CR line endings'
	.a 'FILE'
	.c 'file'
	if {!~ $#* 1} {
		.usage cr2lf
	} else {
		let (f = `mktemp) {
			cat $* | tr \r \n > $f
			mv $f $*
		}
	}
}

fn crlf2lf {|*|
	.d 'Convert a file having CRLF line endings'
	.a 'FILE'
	.c 'file'
	if {!~ $#* 1} {
		.usage crlf2lf
	} else {
		let (f = `mktemp) {
			cat $* | tr -d \r > $f
			mv $f $*
		}
	}
}

fn deb2rpm {|*|
	.d 'Convert a .deb archive to .rpm'
	.a 'DEB_FILE'
	.c 'file'
	.i 'Assumptions: Same arch; binary package; for use on this host;'
	.i 'archive filename prefix (to version) same as package name.'
	if {!~ $#* 1} {
		.usage deb2rpm
	} else {
		let (base = `{cd `{dirname $*}; pwd}; arch = `arch; \
		fn-pm = {|b l| escape {|fn-return| for d $l {
					if {~ $b $d^* && !~ $d $b} {return $d}}
		}}) {
			sudo alien -rg $*
			pkg = <={pm `{basename $*} `` \n ls}
			~ $pkg () && throw error deb2rpm \
							'can not match package'
			echo Base: $base
			echo Matched package: $pkg
			access -f $pkg^-*^.$arch^.rpm && {
				sudo rm -rf $pkg
				throw error deb2rpm \
						$pkg^-*^.$arch^.rpm^' exists'
			}
			fork {
				cd $pkg
				sudo sed -i 's|%dir "[^"]\+"|#&|g' \
								$pkg^-*^.spec
				sudo rpmbuild --quiet \
						--buildroot $base^/$pkg \
						--target $arch -bb \
						$base^/$pkg^/$pkg^-*^.spec
			}
		}
	}
}

fn dots {|*|
	.d 'Display dots in place of text lines'
	.a '[MULTIPLIER]'
	.c 'file'
	~ $* () && * = 1
	let (n = 0; m = 0; t = 0) {
		while {!~ <=read ()} {
			t = `($t+1)
			m = `($m+1)
			~ $m $* && {
				m = 0
				n = `($n+1)
				printf .
				~ $n 72 && {printf \n; n = 0}
			}
		}
		printf \n'{%d}'\n $t
	}
}

fn hd {|*|
	.d 'Simple hex dump'
	.a '[FILE]'
	.c 'file'
	if {$#* :gt 1} {
		.usage hd
	} else {
		hexdump $* -e '"%07.7_Ax  (%_Ad)\n"' \
			-e '"%07.7_ax  " 8/1 "%02x " "  " 8/1 "%02x " "\n"'
	} | less -iRFXS
}

fn import-abook {|*|
	.d 'Import vcard to abook'
	.a 'VCARD_FILE'
	.c 'file'
	if {~ $#* 0} {
		.usage import-abook
	} else {
		access -f ~/.abook/addressbook \
			&& mv ~/.abook/addressbook ~/.abook/addressbook-OLD
		abook --convert --infile $* --informat vcard \
			--outformat abook --outfile ~/.abook/addressbook
		chmod 600 ~/.abook/addressbook
	}
}

fn list {|*|
	.d 'List file with syntax highlighting'
	.a '[-s SYNTAX] FILE'
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
		let (syn; pf; lc; w = 6; err; \
			lpath = ~/.config/vis/lexers \
				/usr/local/share/vis/lexers; \
			fn-canon = {|ext|
				%with-dict {|d|
					result <={%objget $d $ext $ext}
				} (1 man 3 man 5 man 7 man ascii text txt text
					conf text README text log text
					iso-8859 text c ansi_c sh bash
					dash bash posix bash bourne-again bash
					patch diff md markdown fs forth f forth
					4th forth adb ada ads ada gpr ada
					rs rust rst rest p pascal py python
					js javascript es rc hs haskell
					build ruby cxx cpp hxx cpp)} \
			) {
			if {~ $*(1) -s} {
				syn = $*(2)
				* = $*(3 ...)
			} else {
				{!~ $#* 1 && throw error list 'too many files'}
				{~ $#* 1 && err = <={access -fr -- $*}} \
					|| {throw error list $err}
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
						| tr '[[:upper:]]' \
								'[[:lower:]]'}
				syn = <={canon $syn}
				~ <={access -f $lpath/^$syn^.lua} 0 \
					|| syn = ()
			}
			~ $syn () && syn = null
		}
		if {file $*|grep -q 'CR line terminators'} {
			pf = `mktemp
			cat $*|tr \r \n >$pf
		} else {
			pf = $*
		}
		lc = `{cat $*|wc -l}
		if {~ $lc ????? 9999} {w = 5} \
		else if {~ $lc ???? 999} {w = 4} \
		else if {~ $lc ??? 99} {w = 3} \
		else if {~ $lc ?? 9} {w = 2} \
		else if {~ $lc ?} {w = 1}
		# NOTE: `vis-highlight` may not produce color with all lexers.
		vis-highlight $syn <{expand $pf} \
			| nl -ba -s' ' -w$w >[2]/dev/null \
				| sed 's/^\([ 0-9]\+\)\(.*\)$/' \
					^<=.%an^<=.%as^'\1'^<=.%an^'\2/' \
				| tr -d \x0f | less -~ -'#' .2 -ch0 -iRFXS
			~ $pf $* || rm -f $pf
		}
	}
}

fn lpman {|man|
	.d 'Print a man page'
	.a 'PAGE'
	.c 'file'
	if {!~ $#man 1} {
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
	if {!~ $#md 1} {
		.usage lpmd
	} else {
		cmark $md | w3m -T text/html -cols 80 | sed 's/^.*/    &/' \
			| lpr -o page-top=60 -o page-bottom=60 \
				-o page-left=60 -o lpi=8 -o cpi=12
	}
}

fn lprst {|rst|
	.d 'Print a reStructuredText file'
	.a 'FILE'
	.c 'file'
	if {!~ $#rst 1} {
		.usage lprst
	} else {
		rst2html -r 4 $rst | w3m -T text/html -cols 80 \
			| sed 's/^.*/    &/' \
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
		cmark $* | w3m -X -o confirm_qq=0 -T text/html -cols 80
	}
}

fn qpdec {|*|
	.d 'Decode quoted-printable text file'
	.a 'FILE'
	.c 'file'
	if {!~ $#* 1} {
		.usage qpdec
	} else {
		cat $*|perl -MMIME::QuotedPrint=decode_qp \
						-e 'print decode_qp join"",<>'
	}
}

fn qpenc {|*|
	.d 'Encode text file as quoted-printable'
	.a 'FILE'
	.c 'file'
	if {!~ $#* 1} {
		.usage qpenc
	} else {
		cat $*|perl -MMIME::QuotedPrint=encode_qp \
						-e 'print encode_qp join"",<>'
	}
}

fn rstv {|*|
	.d 'reStructuredText file viewer'
	.a 'RST_FILE'
	.c 'file'
	if {!~ $#* 1} {
		.usage rstv
	} else if {!access -f $*} {
		echo 'file?'
	} else {
		rst2html -r 4 $* | w3m -X -o confirm_qq=0 -T text/html -cols 80
	}
}

fn shuffle {|*|
	.d 'Shuffled list of files in directory'
	.a 'DIRECTORY [FILTER_GLOB]'
	.c 'file'
	let (dir = $*(1); filt = $*(2)) {
		~ $filt () && filt = '*'
		find -L $dir -type f -iname $filt|shuf \
			|awk '/^[^/]/ {print "'`pwd'/"$0} /^\// {print}'
	}
}

fn tsview {|*|
	.d 'Typescript viewer'
	.a '[FILE]'
	.a '(none)  # ./typescript'
	.c 'file'
	if {!~ $#* 1} {
		* = ./typescript
	}
	teseq -CLDE $*|reseq - -|col -b|less -FXi
}

fn unzipd {|*|
	.d 'Unzip into a directory named after the archive'
	.a 'ZIP_FILE'
	.c 'file'
	if {!~ $#* 1} {
		.usage unzipd
	} else {
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
}

fn vman {|*|
	.d 'View man page'
	.a '[man_OPTS] PAGE'
	.c 'file'
	%only-X
	result %with-terminal
	if {~ $#* 0} {
		.usage vman
	} else {
		%with-suffixed-tempfile f .ps {
			/usr/bin/man -Tps $* >$f
			/usr/bin/zathura $f #>/dev/null >[2=1]
		}
	}
}

fn xd {|*|
	.d 'Simple XML dump'
	.a '[FILE]'
	.c 'file'
	if {$#* :gt 1} {
		.usage xd
	} else if {~ $* ()} {
		cat|xmllint --format -
	} else {
		xmllint --format $*
	} | less -iRFXS
}

fn zathura {|*|
	.d 'Document viewer'
	.a '[zathura_OPTIONS]'
	.c 'file'
	.f 'wrap'
	result %with-terminal
	local (embed) {
		!~ $XEMBED () && embed = -e $XEMBED
		setsid /usr/bin/zathura $embed $* >/dev/null >[2=1] &
	}
	true
}
