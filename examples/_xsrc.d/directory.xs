fn dt {|*|
	.d 'List top directory usage'
	.a '[-a] [DIR]'
	.c 'directory'
	%with-terminal dt {let (eo = --exclude './.*') {
		if {~ $*(1) -a} {eo = ; * = $*(2 ...)}
		du $eo -t1 -h -d1 $*|grep -vE '^[.0-9KMGTPEZY]+'\t'\.$' \
			|sort -h -r -k1|head -15
	} | %wt-pager}
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
	.d 'ls -A'
	.c 'directory'
	.r 'll ls lt'
	result %with-terminal
	ls -A $*
}

fn ll {|*|
	.d 'ls -lh'
	.c 'directory'
	.r 'la ls lt'
	result %with-terminal
	ls -lh $*
}

fn ls {|*|
	.d 'ls'
	.c 'directory'
	.a '[[-O] ls_ARGS]  # -O: no directories-first'
	.r 'la ll lt'
	let (group = --group-directories-first; arg; lsargs) {
		for arg $* {
			if {~ $arg -O} {
				group =
			} else {lsargs = $lsargs $arg}
		}
		if {!test -t 0 || test -t 1} {
			%with-terminal ls {
				/usr/bin/ls -C -v --color=yes $group $lsargs \
								|%wt-pager
			}
		} else {
			/usr/bin/ls $group $lsargs
		}
	}
}

fn lt {|*|
	.d 'ls -lhtr'
	.c 'directory'
	.r 'la ll ls'
	result %with-terminal
	ls -lhtr $*
}

fn src {|*|
	.d 'pushd to K source directories'
	.a '[NAME]'
	.a '(none)  # list source directories'
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

fn td {|*|
	.d 'Display tree of directories'
	.a '[-L LEVELS] [DIRECTORY]'
	.c 'directory'
	%with-terminal td {tree -dC $* | %wt-pager}
}

fn treec {|*|
	.d 'Display filesystem tree'
	.a '[-L LEVELS] [DIRECTORY]'
	.c 'directory'
	%with-terminal treec {tree --du -hpugDFC $* | %wt-pager}
}
