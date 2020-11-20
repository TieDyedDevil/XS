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
