# Utilities referenced by library functions

fn notify {|title message|
	.d 'Pop up a titled message'
	.a 'TITLE MESSAGE...  # black; 3 sec at top-screen'
	.a 'COLOR\|TITLE MESSAGE...  # time and position depends upon color'
	.a '  # white: 1 sec at mid-screen'
	.a '  # white3: 3 sec at mid-screen'
	.a '  # red, green, blue, magenta, yellow, cyan: 5 sec at 1/3 screen'
	.a 'persist\|TITLE MESSAGE...  # at bottom-screen until Escape'
	.c 'system'
	.i 'Color-coding recommended usage:'
	.i ' (default)  synchronous'
	.i ' white      asynchronous, expected, <10s wait'
	.i ' white3     asynchronous, expected, 0 to >10s wait'
	.i ' red, green, blue, magenta, yellow, cyan'
	.i '            asynchronous, unexpected, informational'
	.i ' persist    asynchronous, unexpected, important'
	.i 'NOTE: Ad-hoc notifications may use the reserved color `cyan`;'
	.i '      This color will not be used by any system function.'
	.r 'nh report'
	#
	if {~ $title ()} {
		.usage notify
	} else {let (v; flag; tt; opts; p) {
		(_ v) = <=%X-screen-size
		(flag tt) = <={~~ $title *\|*}
		~ $tt () && tt = $title
		switch $^flag (
		'' {p = 3; opts = -fg white -bg gray25}
		green {p = 5; opts = -y `($v/3) -fg white -bg green4}
		yellow {p = 5; opts = -y `($v/3) -fg black -bg yellow3}
		red {p = 5; opts = -y `($v/3) -fg white -bg red4}
		blue {p = 5; opts = -y `($v/3) -fg white -bg blue3}
		magenta {p = 5; opts = -y `($v/3) -fg black -bg magenta}
		cyan {p = 5; opts = -y `($v/3) -fg black -bg cyan}
		white {p = 1; opts = -y `($v/2) -fg black -bg white}
		white3 {p = 3; opts = -y `($v/2) -fg black -bg white}
		persist {p =; opts = -y $v -fg white -bg purple \
			-e 'key_Escape=ungrabkeys,exit;onstart=grabkeys' \
				^';button1=ungrabkeys,exit'}
		{throw error notify 'color?'})
		echo '^fg()'^$tt^' ^fg(#708090)|^fg()' $^message \
			| stdbuf -o0 sed 's/^\(.*\)$/^pa(20)&/' \
			| dzen2 -ta l $opts -p $p -fn 'Noto Sans Medium-' \
							^$INFO_FONTSIZE &
		echo $title \| $message | ts >> ~/.local/run/notify.log
	}}
	true
}

fn nh {
	.d 'Notification history'
	.c 'system'
	.r 'notify report'
	%with-terminal nh {
		tac <{echo <=.%ad^latest} ~/.local/run/notify.log | %wt-pager
	}
}

fn report {|title message|
	.d 'Display or `notify` a titled message, depending upon stdout'
	.a 'See `notify`.'
	.c 'system'
	.r 'nh notify'
	if {test -t 0} {
		let ((c t) = <={~~ $title *\|* *}; fg) {
			~ $t () && {t = $c; c =}
			switch $^c (
			white {fg = 7}
			red {fg = 1}
			green {fg = 2}
			blue {fg = 4}
			magenta {fg = 5}
			yellow {fg = 3}
			cyan {fg = 6}
			{fg = 7}
			)
			printf '%s%s: %s%s'\n <={.%af $fg} $t $^message <=.%an
			echo $title \| $message | ts >> ~/.local/run/notify.log
		}
	} else {notify $title $message}
}

%cfn {!access -x /usr/local/bin/vis-highlight} list {|*|
	.d 'List file with syntax highlighting'
	.a '[+] [-s SYNTAX] FILE  # +: keep short file open'
	.a '-l  # list SYNTAX names'
	.i 'Control characters and CSI sequences are stripped.'
	.i 'Tabs are expanded with a width of 8.'
	.c 'file'
	if {~ $#* 0} {
		.usage list
	} else if {~ $* -l} {
		source-highlight --lang-list | cut -d= -f2 \
			| xargs -I\{\} basename \{\} | sed s/\.lang\$// \
			| sort | uniq | column -c `{tput cols} | less -iFX
	} else {
		let (keep; syn; pf; lc; w = 6; err; \
		fn-canon = {|ext|
			%with-dict {|d|
				result <={%objget $d $ext $ext}
			} (ascii txt conf txt README txt log txt iso-8859 txt
				xinitrc sh dash sh posix sh bourne-again sh
				patch diff
				adb ada ads ada gpr ada
				rs rust p pascal py python
				js javascript hs haskell
				build ruby cxx cpp hxx cpp
				tcl/tk tcl wish tcl tk tcl)} \
		) {
			if {~ $*(1) +} {
				keep = -+F -+X
				* = $*(2 ...)
			}
			if {~ $*(1) -s} {
				syn = $*(2)
				* = $*(3 ...)
			} else {
				{!~ $#* 1 && throw error list 'too many files'}
				{~ $#* 1 && err = <={access -fr -- $*}} \
					|| {throw error list $err}
				syn = `{echo $*|sed 's/^.*\.\([^.]\+\)$/\1/'}
				syn = <={canon $syn}
				~ $syn `{source-highlight --lang-list \
						| cut -d= -f2 \
						| sed s/\.lang\$// \
						| sort | uniq} \
					|| syn = ()
			}
			~ $syn () && syn = txt
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
			source-highlight -s $syn -f esc \
				-i <{cat $pf|%strip-csi|%strip-ctl|expand} \
				| nl -ba -s' ' -w$w >[2]/dev/null \
					| sed 's/^\( *[0-9]\+\)\(.*\)$/' \
						^<=.%an^<=.%as^'\1' \
								^<=.%an^'\2/' \
					| tr -d \x0f \
					| less -~ -'#' .2 -ch0 -iRFXS $keep
			~ $pf $* || rm -f $pf
		}
	}
}

%cfn {access -x /usr/local/bin/vis-highlight} list {|*|
	.d 'List file with syntax highlighting'
	.a '[+] [-s SYNTAX] FILE  # +: keep short file open'
	.a '-l  # list SYNTAX names'
	.i 'Control characters and CSI sequences are stripped.'
	.i 'Tabs are expanded with a width of 7.'
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
		let (keep; syn; pf; lc; w = 6; err; \
			lpath = ~/.config/vis/lexers \
				/usr/local/share/vis/lexers; \
			fn-canon = {|ext|
				%with-dict {|d|
					result <={%objget $d $ext $ext}
				} (1 man 3 man 5 man 7 man ascii text txt text
					conf text README text log text
					iso-8859 text c ansi_c sh bash
					xinitrc bash
					dash bash posix bash bourne-again bash
					patch diff md markdown
					fs forth f forth 4th forth fth forth
					adb ada ads ada gpr ada
					rs rust rst rest p pascal py python
					js javascript es rc hs haskell
					build ruby cxx cpp hxx cpp
					tcl/tk tcl wish tcl tk tcl)} \
			) {
			if {~ $*(1) +} {
				keep = -+F -+X
				* = $*(2 ...)
			}
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
			# NOTE: `vis-highlight` may not produce color
			# with all lexers.
			vis-highlight $syn \
				<{cat $pf|%strip-csi|%strip-ctl|expand} \
				| nl -ba -s' ' -w$w >[2]/dev/null \
					| sed 's/^\( *[0-9]\+\)\(.*\)$/' \
						^<=.%an^<=.%as^'\1' \
								^<=.%an^'\2/' \
					| tr -d \x0f \
					| less -~ -'#' .2 -ch0 -iRFXS $keep
			~ $pf $* || rm -f $pf
		}
	}
}
