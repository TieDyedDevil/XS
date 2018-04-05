fn dt {|*|
	.d 'List top directory usage'
	.a '[-a] [DIR]'
	.c 'directory'
	let (eo = --exclude './.*') {
		if {~ $*(1) -a} {eo = ; * = $*(2 ...)}
		du $eo -t1 -h -d1 $*|grep -vE '^[.0-9KMGTPEZY]+'\t'\.$' \
			|sort -h -r -k1|head -15
	}
}
fn doc {|*|
	.d 'pushd to documentation directory of package'
	.a 'PACKAGE_NAME_GLOB'
	.a '-n PACKAGE_NAME'
	.c 'directory'
	if {~ $#* 0} {
		.usage doc
	} else if {~ $*(1) -n} {
		doc /$*(2)^\$
	} else if {!~ $* ()} {
		let (pl) {
			pl = `{find -L /usr/share/doc /usr/local/share/doc \
				-mindepth 1 -maxdepth 1 -type d \
				|grep -i '/usr.*/share/doc.*'^$*}
			if {~ $#pl 1} {
				pushd $pl
			} else if {~ $#pl ???*} {
				throw error doc 'more than 99 matches'
			} else {
				for p ($pl) {echo `{basename $p}}
				echo $#pl matches
			}
		}
	}
}
fn la {|*|
	.c 'directory'
	.r 'll ls lt'
	ls -a $*
}
fn ll {|*|
	.c 'directory'
	.r 'la ls lt'
	ls -lh $*
}
fn ls {|*|
	.c 'directory'
	.a '[ls_ARGS|-P]'
	.r 'la ll lt'
	if {~ $* -P} {
		* = `{echo $*|sed 's/-P//'}
		/usr/bin/ls --group-directories-first -v --color=yes $* \
			| less -RFXi
	} else {
		/usr/bin/ls --group-directories-first -v --color=auto $*
	}
}
fn lt {|*|
	.c 'directory'
	.r 'la ll ls'
	ls -lhtr $*
}
fn src {|*|
	.d 'pushd to K source directories'
	.a '[NAME]'
	.c 'directory'
	if {~ $#* 0} {
		find /usr/local/src -maxdepth 1 -mindepth 1 -type d \
			|xargs -I\{\} basename \{\}|column -c `{tput cols}
	} else {
		if {access -d /usr/local/src/$*} {
			pushd /usr/local/src/$*
		} else {echo 'not in /usr/local/src'}
	}
}
fn treec {|*|
	.d 'Display filesystem tree'
	.a 'DIRECTORY'
	.c 'directory'
	tree --du -hpugDFC $* | less -iRFX
}
fn tsmwd {
	.d 'Return to tsm working directory'
	.c 'directory'
	if {!~ $TSMWD ()} {cd $TSMWD; echo $TSMWD} else echo .
}
