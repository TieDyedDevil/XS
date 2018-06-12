fn bell {|*|
	.d 'Bell control'
	.a 'on|off'
	.c 'wm'
	%only-X
	switch $^* (
		off {if {pacmd list-modules|grep -q module-x11-bell} {
				pacmd unload-module module-x11-bell
		}}
		on {pacmd load-module module-x11-bell sample=x11-bell \
			display=:0.0}
		{
			if {pacmd list-modules|grep -q module-x11-bell} {
				echo On
			} else {
				echo Off
			}
		}
	)
}
fn boc {|*|
	.d 'Bell on completion'
	.a 'COMMAND'
	.c 'wm'
	.r '3up bari barre dual em hc mons osd quad r updres wmb'
	%only-X
	unwind-protect {$*} {printf %c \a}
}
fn lock {|*|
	.d 'Lock screen'
	.a '-t  # transparent lock, disable DPMS; X only'
	.a '-a  # lock all consoles; vt only'
	.c 'wm'
	.r 'screensaver'
	if {~ $DISPLAY ()} {
		vlock $*
	} else {
		~/.local/bin/lock $*
	}
}
fn mons {
	.d 'Report connect monitors'
	.c 'wm'
	%only-X
	xrandr | grep -w -e Screen -e connected | sed 's/([^)]\+)//'
}
fn screensaver {|*|
	.d 'Query/set display screensaver enable'
	.a '[on|off]'
	.a '(none)  # show current'
	.c 'wm'
	.r 'lock'
	let (error = false) {
		if {~ $DISPLAY ()} {
			if {!~ `tty */tty*} {throw error screensaver 'not a tty'}
			if {~ $#* 0} {
				timeout = `{cat /sys/module/kernel/\
					^parameters/consoleblank}
				if {~ $timeout 0} {echo Off} \
				else {echo On}
			} else {
				switch $* (
				on {setterm -blank 15 -powerdown 15 >>/dev/tty}
				off {setterm -blank 0 -powerdown 0 >>/dev/tty}
				{error = true})
			}
		} else {
			if {~ $#* 0} {
				let (timeout) {
					timeout = `{xset q|grep timeout \
						|awk '{print $2}'}
					if {~ $timeout 0} {echo Off} \
					else {echo On}
				}
			} else {
				switch $* (
				on {xset +dpms; xset s on; xset s 900 0}
				off {xset -dpms; xset s off}
				{error = true})
			}
		}
		if $error {throw error screensaver 'on or off'}
	}
}
fn startwm {
	.d 'Start X window manager'
	.c 'wm'
	if {!~ $DISPLAY ()} {
		throw error startwm 'already running'
	} else if {!~ `tty *tty*} {
		throw error startwm 'run from console'
	} else {
		cd
		access -f .startx.log && mv .startx.log .startx.log.old
		exec startx -- -logverbose 0 >.startx.log >[2=1]
	}
}
fn updres {
	.d 'Update X and GTK resolution to match display'
	.c 'wm'
	.adapt-resolution
}
fn wallgen {
	.d 'Generate wallpaper'
	.c 'wm'
	%only-X
	let (n = <=$&random; \
	r = <={{|x y| result `(1.0*$x/$y)} <=%X-screen-size}; \
	aspect) {
		switch `{echo $r|cut -c-4} (
		1.33 {aspect = 4x3}
		1.77 {aspect = 16x9}
		2.38 {aspect = 21x9}
		{aspect = 2x2}
		)
		switch `($n%2) (
		0 {xmartin -static -perturb 1117}
		1 {xmartin -static -tile $aspect}
		) >[2]/dev/null
	}
}
fn wallpaper {|*|
	.d 'Set wallpaper'
	.a '[-m MONITOR] FILE-OR-DIRECTORY'
	.a '[-m MONITOR] DELAY_MINUTES DIRECTORY'
	.a '-c  # cycle'
	.a '(none)  # restore root window'
	.c 'wm'
	%only-X
	local (pageopt = $pageopt) {let (monopt = '') {
		let (geom; mon; re = 'while true \{wallpaper'; \
		fn-running = {pgrep -cf 'while true \{wallpaper' >/dev/null}; \
		fn-cycle = {|d m|setsid >[2]/dev/null xs -c \
			`` '' {printf 'while true {wallpaper %s %s; sleep %s}' \
					$monopt $d `($m*60)} &}) {
			if {~ $* -c} {
				if {running} {
					 pkill -P `{pgrep -f $re}
				} else {
					wallgen
					#throw error wallpaper \
					#	'not active'
				}
			} else {
				if {~ $*(1) -m} {
					mon = $*(2)
					monopt = $*(1 2); monopt = $^monopt
					* = $*(3 ...)
					geom = `{grep \^$mon <{xrandr}| \
						grep -o '[0-9]\+x[0-9]\+' \
							^'+[0-9]\++[0-9]\+'}
				}
				!~ $geom () && pageopt = -page $geom
				switch $#* (
				1 {	let (f) {
						access -f $* && f = $*
						access -d $* && wallpaper \
							`{find -L $* \
							\( -name '*.jpg' \
							-o -name '*.png' \) \
							|shuf|head -1}
						!~ $f () && {
							display -window root \
								$pageopt $f
							echo $f >~/.wallpaper
						}
					}
				}
				2 {	let (m = $*(1); d = $*(2)) {
						access -d $d && {
							wallpaper
							cycle $d $m
						}
					}
				}
				{	if {running} {
						kill -- -^`{pgrep -f $re}
					}
					xsetroot -solid gray15
				})
			}
		}
	}}
}
fn xdpi {
	.d 'X display info'
	.c 'wm'
	{xrdb -query|grep 'Xft\.dpi'|tr \t ' '; xdriinfo}|column -s: -t
}
