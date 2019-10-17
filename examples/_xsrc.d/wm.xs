fn animate {|*|
	.d 'Animated distractions in root window'
	.a '[off|restart]'
	.r 'aquarium wallgen wallpaper'
	.c 'wm'
	%only-X
	result %with-terminal
	let (pf = ~/.local/share/animate.pid) {
		catch {
			modes = allfractal,allspace,allgeometry,allautomata
		} {
			. ~/.local/share/xlock-modes
			~ $modes () && throw error xlock-modes 'no modes'
		}
		if {~ $* off} {
			if {access -f $pf} {
				kill `{cat $pf}
				rm $pf
				wallgen -c
			}
		} else if {~ $* restart} {
			animate off
			animate
		} else if {access -f $pf && kill -0 `{cat $pf} >[2]/dev/null} {
			echo Running
		} else {
			xsetroot -solid black
			xlock -nolock -inroot -nice 15 -modelist $modes \
				-fullrandom -duration 43 -erasemode venetian \
				-erasedelay 150000 -visual truecolor &
			echo $apid >~/.local/share/animate.pid
			echo Started
		}
	}
}

fn aquarium {|*|
	.d 'Aquarium in root window'
	.a '[off|xfishtank_OPTIONS]'
	.r 'animate wallgen wallpaper'
	.c 'wm'
	%only-X
	result %with-terminal
	if {~ $* off} {
		pkill xfishtank
		wallgen -c
	} else {
		pgrep -c xfishtank >/dev/null || {xfishtank -d -b 73 -f 5 \
							-i 0.03 -r 0.17 $* &}
		true
	}
}

fn boc {|*|
	.d 'Bell on completion'
	.a 'COMMAND'
	.c 'wm'
	%only-X
	unwind-protect {$*} {printf %c \a}
}

fn displays {
	.d 'List display connections'
	.c 'wm'
	%only-X
	%with-terminal displays {
	xrandr|grep '^[^ ]'|grep -v '^Screen'|cut -d\( -f1 \
		| sed 's/^[^ ]\+ connected $/&Zinactive/'|sort -k2 -k1 \
		| sed 's/Zinactive/inactive/' | %wt-pager
	} # %with-terminal
}

fn lock {|*|
	.d 'Lock screen'
	.a '-t  # transparent lock w/ notification, disable DPMS; X only'
	.a '-L  # login lock'
	.a '-w  # lock screensaver in a window; no lock'
	.a '-a  # lock all consoles; vt only'
	.c 'wm'
	.r 'screensaver'
	result %with-terminal
	if {~ $DISPLAY ()} {
		vlock $*
	} else {
		~/.local/bin/lock $*
	}
	true
}

fn mirror {|*|
	.d 'Mirror screen to connected, unused display (HDMI, DP or VGA)'
	.a '[off]'
	.c 'wm'
	.r 'secondary'
	%only-X
	result %with-terminal
	let (state; port) {
		if {~ $* off} {
			state = --off
			port = `{%active-displays|tail -1}
		} else {
			state = --auto
			port = `{%unused-displays \
					|grep '^\(HDMI\|DP\|VGA\)'|head -1}
		}
		~ $port () && throw error mirror 'connected?'
		xrandr --output $port $state
	}
}

fn mons {
	.d 'Report connected monitors'
	.c 'wm'
	%only-X
	%with-terminal mons {
	xrandr | grep -w -e connected | sed 's/([^)]\+)//' \
		| sed 's/ connected//' | sed 's/  / /' \
		| sed 's/\([0-9]\+\)mm x \([0-9]\+\)mm.*/\1x\2mm/' \
		| sed 's/\([0-9]\+\) x \([0-9]\+\)/\1x\2/g' \
		| awk -f <{cat <<'EOF'
BEGIN { l = 0 }
{
	sl = match($0, /[0-9]+x[0-9]+mm$/)
	if (sl) {
		sz = substr($0, sl)
		gsub(/mm/, "", sz)
		split(sz, wh, /x/)
		wh[1] = wh[1] / 25.4
		wh[2] = wh[2] / 25.4
		diag = sprintf("%4.1f", sqrt(wh[1]*wh[1]+wh[2]*wh[2]))
		gp = match($0, /[0-9]+x[0-9]+/)
		ge = substr($0, gp, RLENGTH)
		split(ge, ss, /x/)
		if (wh[2] != 0) pr = (wh[1]/ss[1])/(wh[2]/ss[2]);
		else {diag = "?"; pr = "?"}
		dl = match($0, /[0-9]+x[0-9]+/)
		dxy = substr($0, dl, RLENGTH)
		split(dxy, xy, /x/)
		tf = "/tmp/xy" l
		system("xs -c 'echo <={%aspect " xy[1] " " xy[2] "}' >" tf)
		getline asp <tf
		system("rm -f " tf)
		l = l+1
		if (wh[1] != 0) ppi = sprintf("%.0f", ss[1]/wh[1]);
		else ppi = "?"
		print $0 " " asp " " diag "in⧅ " pr "∺ " ppi "ppi⸬"
	} else if (match($0, /^Screen /)) {
		print $0
	} else {
		print $0 "inactive Z"
	}
}
EOF
	} | sort | sed 's/inactive Z/inactive/' | %wt-pager
	} # %with-terminal
}

fn remote {|*|
	.d 'Open a terminal or client on a remote system'
	.a 'HOST [CLIENT]  # default st'
	.c 'system'
	%only-X
	result %with-terminal
	if {~ $* ()} {
		.usage remote
	} else if {!~ $#* 1} {
		ssh -fX $*
	} else {
		ssh -fX $* env TERM=st-256color xs -lc stq
	}
}

fn screensaver {|*|
	.d 'Query/set display screensaver enable'
	.a '[on|off]'
	.a '(none)  # show current'
	.c 'wm'
	.r 'lock'
	let (error = false) {
		if {~ $DISPLAY ()} {
			if {!~ `tty */tty*} {
				throw error screensaver 'not a tty'
			}
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
					timeout = `{xset q|grep 'DPMS is' \
						|awk '{print $3}'}
					if {~ $timeout Disabled} {echo Off} \
					else {echo On}
				}
			} else if {systemd-detect-virt -q} {
				throw error screensaver 'not in virt'
			} else {
				switch $* (
				on {xset +dpms}
				off {xset -dpms}
				{error = true})
			}
		}
		if $error {throw error screensaver 'on or off'}
	}
}

fn secondary {|*|
	.d 'Activate connected, unused display (HDMI, DP or VGA)'
	.a '[off]'
	.c 'wm'
	.r 'mirror'
	%only-X
	result %with-terminal
	let (state; port; prnm; prsz; prx; pry; prefx; prefy) {
		if {~ $* off} {
			state = --off
			port = `{%active-displays-nopoll|tail -1}
		} else {
			(prnm prsz) = `{%active-displays-info}
			(prx pry _) = <={~~ $prsz *x*+*}
			port = `{%unused-displays \
					|grep '^\(HDMI\|DP\|VGA\)'|head -1}
			(prefx prefy) = <={~~ `{%preferred-size $port} *x*}
			# TODO
			# Given, for example, a primary display of 3440x1440
			# and a secondary of 1920x1080, I'd like the secondary
			# to appear to Xorg as 2560x1440, mapped onto the
			# physical 1920x1080. The combination should appear
			# to Xorg as 3440x1440+0+0 and 2560x1440+3440+0.
			# I'm hoping to achieve continuity across displays
			# having the same physical height despite differences
			# in the displays' resolution or aspect.
			state = --auto --right-of $prnm
		}
		~ $port () && throw error secondary 'connected?'
		aquarium off
		xrandr --output $port $state
	}
}

fn startwm {
	.d 'Start X window manager'
	.c 'wm'
	if {!~ $DISPLAY ()} {
		throw error startwm 'already running' \
			`{pgrep -lP `{pgrep xinit}|grep -v Xorg|cut -d' ' -f2}
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
	%only-X
	.adapt-resolution <=%xscale
}

fn scaled {|*|
	.d 'Scale display'
	.a 'DISPLAY WIDTH HEIGHT'
	.a 'DISPLAY reset  # to preferred size'
	%only-X
	if {!~ $#* 3 && !{~ $#* 2 && ~ $*(2) reset}} {
		.usage scaled
	} else {
		let ((disp horz vert) = $*) {
		let ((nx ny) = `{%preferred-size $disp|tr x ' '}; sx; sy) {
			{~ $horz reset} && {(horz vert) = $nx $ny}
			sx = `(1.0*$horz/$nx); sy = `(1.0*$vert/$ny)
			xrandr --output $disp --mode $nx^x^$ny \
				--panning $horz^x^$vert^/^$horz^x^$vert \
				--scale $sx^x^$sy
		}
		}
	}
}

fn wallgen {|*|
	.d 'Generate wallpaper'
	.a '(none)  # new image'
	.a '-g  # gray'
	.a '-b  # blackout'
	.a '-r  # recolor'
	.a '-l  # list'
	.a '-c SECONDS  # cycle'
	.a '-c  # stop cycle'
	.i 'Image creation is suppressed when a fullscreen window is present.'
	.r 'animate aquarium wallpaper'
	.c 'wm'
	%only-X
	result %with-terminal
	escape {|fn-return| let (pidfile = ~/.local/share/wallgen-r.pid) {
		if {~ $*(1) -c} {
			if {~ $#* 1} {
				access -f $pidfile && {
					pkill -g `{cat $pidfile}
					rm -f $pidfile
				}
			}
			if {~ $#* 2} {
				wallgen -c
				setsid xs -c {
					forever {
						nice -n 15 xs -c wallgen
						sleep $*(2)
					} &
					echo $apid >$pidfile
				} &
			}
			return
		}
	}
	if {~ $* -g} {
		wallgen -c
		xsetroot -solid gray15
	} else if {~ $* -b} {
		wallgen -c
		xsetroot -solid black
	} else if {~ $* -r} {
		xmartin -static `{cat ~/.xmartin} >[2]/dev/null
	} else if {~ $* -l} {
		%with-terminal 'wallgen -l @ '^`` \n date {
			fold -s -w 70 <{echo xmartin `{cat ~/.xmartin} \*} \
					|sed 's/$/ \\/'|sed 's/ \* \\//' \
					|sed '2,$s/^.*$/  &/' \
				|%wt-pager
		}
	} else {
		result <=%fullscreen-window-present ||
			xmartin -static -perturb >[2]/dev/null
	}}
}

fn wallpaper {|*|
	.d 'Choose wallpaper'
	.a '-r  # random'
	.a '-c SECONDS  # cycle'
	.a '-c  # stop cycle'
	.a '(none)  # manual'
	.r 'animate aquarium wallgen'
	.c 'wm'
	%only-X
	result %with-terminal
	escape {|fn-return| let (pidfile = ~/.local/share/wallpaper-r.pid) {
		if {~ $*(1) -c} {
			if {~ $#* 1} {
				access -f $pidfile && {
					pkill -g `{cat $pidfile}
					rm -f $pidfile
				}
			}
			if {~ $#* 2} {
				wallpaper -c
				setsid xs -c {
					forever {wallpaper -r; sleep $*(2)} &
					echo $apid >$pidfile
				} &
			}
			return
		}
	}
	let (d = `` \n {%active-displays-info}) {
		~ $#d 1 || throw error wallpaper 'multiple active displays'
		let (s = `{echo $d|cut -d\t -f2|cut -d+ -f1}) {
			let (p = ~/Pictures/wallpaper-$s) {
				access -d -- $p \
					|| throw error wallpaper 'no '$p
				switch $^* (
				'' {let (i = `` \n {sxiv -bort $p}) {
					~ $#i 1 && display -window root $i
				}}
				-r {display -window root `` \n {shuffle $p \
								|head -1}
				}
				{.usage wallpaper}
				)
			}
		}
	}}
}

fn wins {
	.d 'List X windows'
	.c 'wm'
	%only-X
	%with-terminal wins {
	let (c1; c2; c3; c4; c5; c6; c7; c8; \
	fn-wpd = {
		let (wids = `{wmctrl -l|awk '{print $2}'}; lhs; v) {
			for w $wids {
				$w :ge 0 && {
					lhs = c^`($w+1)
					v = $$lhs
					$lhs = `(1+$v)
				}
			}
			for i (1 2 3 4 5 6 7 8) {
				echo $i \#$(c^$i)
			}
		}
	} \
	) {
		printf %s%s%s\n <=.%ai Workspaces <=.%an
		join <{wmctrl -d|awk '{print gensub(/^[^ ]+/, $1+1, 1)}' \
			|awk '/.  \*/ {print $1 " " $2} ' \
				^'/.  -/ {print $1 " " $2}' \
			|sed 's/^\(.\)  \*/\1  >/'} <{wpd}|column -t|tr \* @
		printf %s%s%s\n <=.%ai Windows <=.%an
		wmctrl -l|awk '{print gensub(/^([^ ]+) +([^ ]+)(.+)$/, ' \
						^'"\\1 " $2+1 "\\3", 1)}' \
			|sed 's/^\([^ ]\+\)\+ 0/\1 */' \
			|sed 's/^\([^ ]\+\) \([^ ]\+\) \(.*\)$/\2\t\1\t\3/' \
			|column -s \t -t \
			|sed 's/^\*.*$/'^<=.%ad^'&'^<=.%an^'/'
	} | %wt-pager
	} # %with-terminal
}

fn xdpi {
	.d 'X display info'
	.c 'wm'
	%only-X
	{xrdb -query|grep 'Xft\.dpi'|tr \t ' '; xdriinfo}|column -s: -t
}

fn xprop {|*|
	.d 'Xorg window properties'
	.c '[xprop_OPTIONS]'
	.c 'wm'
	%only-X
	%with-terminal xprop { /usr/bin/xprop $* | %wt-pager }
}

fn xkill {|*|
	.d 'Kill an Xorg window'
	.a '[xkill_OPTIONS]'
	.c 'wm'
	%only-X
	result %with-terminal
	stq -g 80x2 xs -c { /usr/bin/xkill -frame $* }
}
