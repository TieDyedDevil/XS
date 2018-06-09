fn astat {
	.d 'Display a status screen'
	.c 'system'
	%with-terminal %with-quit {
		watch -t -p -c -n1 \
			'xs -c ''d;load;thermal;vol;played playing'''
	}
}
fn battery {
	.d 'Show battery status'
	.c 'system'
	let (pspath = /sys/class/power_supply; full = 0; curr = 0; \
		ef; ec; en) {
		for d ($pspath/BAT?) {
			access -d $d && {
				ef = `{cat $d/energy_full_design}
				ec = `{cat $d/energy_full}
				en = `{cat $d/energy_now}
				full = `($full+$ec)
				curr = `($curr+$en)
				printf '%s %s (%.2f)'\n \
					`{basename $d} `{cat $d/status} \
					`(1.0*$ec/$ef)
			}
		}
		!~ $curr 0 && printf '%.1f%%'\n `(100.0*$curr/$full)
	}
}
fn d {
	.d 'Date/time (local, UTC, POSIX and TAI)'
	.c 'system'
	date
	date -u
	date +%t%s.%N
	let (a = `` '' {grep \^Leap /usr/share/zoneinfo/leapseconds|cut -f6}; \
		s = `{date +%s}; pf; nf; p; n; l; t) {
		pf = `{grep -e + <<<$a}
		nf = `{grep -e - <<<$a}
		p = $#pf
		n = $#nf
		l = `(10+$p-$n)
		t = `($s+$l)
		printf %+d\t%u\n $l $t
	}
}
fn mail {
	.d 'Check inbox status'
	.c 'system'
	fetchmail -c
}
fn name {|*|
	.d 'Set prompt text and terminal title.'
	.a '[NAME]'
	.c 'system'
	.r 'prompt title'
	if {~ $* ()} {
		prompt ''
		title `{echo $TERM|sed 's/-256color.*//'}
	} else {
		prompt $*
		title $*
	}
}
fn net {|*|
	.d 'Network status'
	.a '[-a]'
	.c 'system'
	%with-terminal {let (flag) {
		if {!~ $* -a} {flag = --active}
		nmcli --fields name,type,device connection show $flag
	}}
}
fn nmtui {
	.d 'Network Manager text UI'
	.c 'system'
	%with-terminal /usr/bin/nmtui
}
fn oc {
	.d 'Onscreen clock'
	.c 'system'
	%with-terminal %with-quit %without-cursor {
		watch -t -n 1 -p -c banner \\' '^\`date +%T\`\; \
						cal -n 3 --color=always
	}
}
fn on {
	.d 'List console logins'
	.c 'system'
	who -Huw
}
fn open {|*|
	.c 'system'
	xdg-open $*
}
fn stt {
	.d 'Tabbed terminal'
	.c 'system'
	/usr/local/bin/tabbed st -w
}
fn swapflush {
	.d 'Flush swapfile(s)'
	.c 'system'
	sudo swapoff -a && sudo swapon -a
}
fn thermal {
	.d 'Summarize system thermal status'
	.c 'system'
	sensors >[2]/dev/null | grep -e '^Physical' -e '^Package' \
				-e '^Core' -e '^fan' | sed 's/ *(.*$//'
}
fn title {|*|
	.d 'Set terminal title'
	.a '[TITLE]'
	.c 'system'
	.r 'prompt name'
	$&echo -n \e]0\;^$^*^\a
}
fn tsm {|*|
	.d 'Terminal session manager'
	.a '[tsm_OPTIONS]'
	.c 'system'
	%preserving-title ~/bin/tsm $*
}
fn tss {|*|
	.d 'Terminal screen size utility'
	.a '-u  # update ROWS and COLUMNS environment vars'
	.a '-d  # delete ROWS and COLUMNS environment vars'
	.a '-q  # display ROWS and COLUMNS environment vars'
	.a '(none)  # show terminal size'
	.c 'system'
	switch $* (
	-d {COLUMNS = ; ROWS =}
	-u {(ROWS COLUMNS) = (`{tput lines} `{tput cols})}
	-q {var COLUMNS ROWS}
	{})
	~ $* () && {printf '%sx%s'\n `{tput cols} `{tput lines}}
}
fn where {
	.d 'Summarize user, host, tty, shell pid and working directory'
	.c 'system'
	printf '%s@%s[%s;%d]:%s'\n \
		$USER `{hostname -s} <={~~ `tty /dev/*} $pid `pwd
}
fn wlpq {
	.d 'Watch lpq until empty'
	.c 'system'
	grep -c '^no entries' >/dev/null <{lpq} || {
		lpq; echo; lpq +20 >/dev/null
	}
	echo 'lpq is empty'
}
fn xcolors {|*|
	.d 'Display X11 colors with RGB values and names'
	.a '[xs_filter_thunk]  # on $r, $g, $b and $d'
	.c 'system'
	%with-read-lines <{showrgb} {|l|
		(r g b d) = `{echo $l}
		let (fn-render = {|f r g b d|
				printf `{.af $f}
				printf \e'[48;2;%d;%d;%dm %03d %03d %03d ' \
					^'(%02x%02x%02x) %30s '^`.an^\n \
					$r $g $b $r $g $b \
					$r $g $b $^d}) {
			if {{~ $* ()} || {eval $*}} {
				render 0 $r $g $b $d
				render 7 $r $g $b $d
			}
		}
	} | less -iFXR
}
