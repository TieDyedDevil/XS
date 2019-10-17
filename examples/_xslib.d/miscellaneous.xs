fn %only-X {
	# Throw an error if not running under X.
	~ $DISPLAY () && throw error %only-X 'Only under X'
}

fn %only-vt {
	# Throw an error if not running on a virtual terminal.
	~ `tty /dev/tty* || throw error %only-vt 'Only in vt'
}

fn %active-displays {
	# Print name of each active display; one per line, primary first.
	# This polls the display hardware for changes.
	xrandr|grep '^[^ ]'|grep ' connected'|sort -r -k3|cut -d' ' -f1
}

fn %active-displays-nopoll {
	# Print name of each active display; one per line, primary first.
	# This does not poll the display hardware for changes.
	xrandr --current|grep '^[^ ]' \
		|grep -e ' connected' -e ' disconnected [0-9]' \
						|sort -r -k3|cut -d' ' -f1
}

fn %active-displays-info {
	# Print <name>\t<geometry> for each active display; one per line.
	# This DOES NOT poll the display hardware for changes.
	xrandr --current|grep '^[^ ]\+ connected' \
		|grep -o '^[^ ]\+.*[0-9]\+x[0-9]\++[0-9]\++[0-9]\+' \
		|sed 's/ primary//'|cut -d' ' -f1,3|tr ' ' \t
}

fn %screen-regions {
	# Print screen regions as LEFT TOP RIGHT BOTTOM coordinates,
	# one per line in display order.
	for dg `` \n %active-displays-info {
		let ((_ g) = `{echo $dg}) {
			let ((xs ys xo yo) = <={~~ $g *x*+*+*}) {
				echo $xo $yo `($xs+$xo) `($ys+$yo)
			}
		}
	}
}

fn %primary-display-size {
	# Print primary display size as WIDTHxHEIGHT.
	xrandr|grep 'connected primary'|cut -d' ' -f4|cut -d+ -f1
}

fn %refresh-xbiff {
	# Refresh xbiff immediately.
	!~ $DISPLAY () && !~ `{xdotool search --class --onlyvisible \
								xbiff} () && {
		let (cw = `{xdotool getactivewindow}) {
			%with-saved-pointer {
				xdotool search --class xbiff windowunmap --sync
				xdotool search --class xbiff windowmap --sync
			}
			!~ $cw () && xdotool windowactivate --sync $cw \
								windowraise $cw
		}
	}
}

fn %window-bounds {
	# Print active window boundaries as LEFT TOP RIGHT BOTTOM.
	let ((xo yo xs ys b) = `{xwininfo -int -id `{xdotool getactivewindow} \
			|grep 'Absolute\|Width\|Height\|Border'|cut -d: -f2}) {
		echo $xo $yo `($xs+$xo+2*$b) `($ys+$yo+2*$b)
	}
}

fn %pt-in-rect {|x y l t r b|
	# Return true if point (x y) is in rectangle (l t r b).
	if {$x :ge $l && $x :le $r && $y :ge $t && $y :le $b} {true} \
	else {false}
}

fn %window-screen-region {
	# Return the screen region (LEFT TOP RIGHT BOTTOM) of the active window.
	escape {|fn-return| {let ((xo yo _ _) = `%window-bounds) {
		for sr `` \n %screen-regions {
			let ((l t r b) = `{echo $sr}) {
				if {%pt-in-rect $xo $yo $l $t $r $b} {
					return $l $t $r $b
				}
			}
		}
	}}}
}

fn %window-move-flush {|*|
	# Move window to the named (left top right bottom) screen edge.
	let (fn-mv = {|x y| xdotool getactivewindow windowmove $x $y}; \
	edge; adj; opp) {
		switch $^* (
		left {mv 0 y}
		top {mv x 0}
		right {
			(_ _ edge _) = <=%window-screen-region
			(opp _ adj _) = `%window-bounds
			mv `($edge-($adj-$opp)) y
		}
		bottom {
			(_ _ _ edge) = <=%window-screen-region
			(_ opp _ adj) = `%window-bounds
			mv x `($edge-($adj-$opp))
		}
		)
	}
}

fn %unused-displays {
	# Print name of connected, inactive displays; one per line.
	# This polls the display hardware for changes.
	xrandr|grep '^[^ ]\+ connected ('|cut -d' ' -f1
}

fn %preferred-size {|display|
	# Print preferred size of display.
	# This polls the display hardware for changes.
	xrandr | awk -f <{cat <<EOF
BEGIN { found=0; }
/^$display^ / { found=1; }
/^   / { if (found && index($$0, "+") != 0) { print $$1; found=0; }}
// {}
EOF
	}
}

fn %primary-display-dpi {
	# Return name and unscaled dpi of primary display.
	# This DOES NOT poll the display hardware for changes.
	let (xrinfo = `{xrandr --current|grep '^[^ ]\+ connected primary'}; \
	size; w; xres; dpi) {
		if {~ $xrinfo ()} {throw error %primary-display-dpi \
							'no primary display'}
		size = <={%argify `{echo $xrinfo|grep -o '[^ ]\+ x [^ ]\+mm' \
			|tr -d ' '}}
		(w _) = <= {~~ $size *mmx*mm}
		if {systemd-detect-virt -q} {
			dpi = 96
		} else {
			if {~ $w 0} {throw error %primary-display-dpi \
						'can''t get resolution'}
			xres = `{echo $xrinfo|grep -o \
					'^[^ ]\+ connected primary [0-9]\+x'}
			xres = <={~~ $xres *x}
			dpi = <={%trunc `(25.4*$xres/$w)}
		}
		result `{echo $xrinfo|cut -d' ' -f1} $dpi
	}
}

fn %ignore-error {|body|
	# Ignore error exception thrown by body.
	catch {|e| !~ $e(1) error && throw $e} {$body}
}

fn %X-screen-size {
	# Return X screen size.
	# This DOES NOT poll the display hardware for changes.
	%only-X
	result `{xrandr --current|grep -o 'current [0-9]\+ x [0-9]\+' \
							|cut -d' ' -f2,4}
}

fn %X-with-cursor {|name body|
	# Run body with named X cursor.
	%only-X
	unwind-protect {
		xsetroot -cursor_name $name
		$body
	} {
		xsetroot -cursor_name X_cursor
	}
}

fn %is-mobile {
	# Return true if system chassis is "mobile".
	let (chassis = `{cat /sys/devices/virtual/dmi/id/chassis_type}) {
		if {{$chassis :ge 8} && {$chassis :le 16}} {true} else {false}
	}
}

fn %multiple-displays {
	# Return true if multiple displays are connected.
	let (count = 0) {
		for e /sys/class/drm/*/edid {
			!~ `{cat $e|wc -c} 0 && count = `($count+1)
		}
		result <={!~ $count 0 1}
	}
}

fn %video-resolution {|file|
	# Display the resolution of video file.
	ffprobe -v error -select_streams v:0 -show_entries \
		stream=width,height -of csv=s=x:p=0 $file
}

fn %aspect {|h v std|
	# Given horizontal and vertical resolution, return display aspect
	# ratio, adjusted for standard usage unless specified as false.
	# Assumes square pixels.
	let ((ra _)= <={%rational `(1.0*$h/$v) 30}) {
		if {result $std} {
			switch $ra (
				64/27 {result 21:9}
				43/18 {result 21:9}
				24/10 {result 21:9}
				{result `{echo $ra|tr / :}}
			)
		} else {result `{echo $ra|tr / :}}
	}
}

fn %xscale {
	# Return ~/.config/xscale or 1.0, as appropriate.
        if {!%multiple-displays} {
		let (xscale = `{cat ~/.config/xscale >[2]/dev/null}) {
			~ $xscale () && xscale = 1.0
			result $xscale
		}
	} else {result 1.0}
}

fn %refocus {
	# Place and destroy a transient window at the pointer location.
	stq -g 1x1 -c transient -t '' &
	xdotool search --sync --class transient >/dev/null
	kill $apid
}

fn %with-saved-pointer {|body|
	# Save the mouse pointer's position, run body, then restore pointer.
	let ((px py) = `{xdotool getmouselocation|cut -d' ' -f1,2 \
								|tr -d xy:}) {
		unwind-protect {
			$body
		} {
			xdotool mousemove $px $py
		}
	}
}

fn %thermal {
	# Print average of temperatures and fan speeds.
        let (tcnt = 0; tsum = 0; fcnt = 0; fsum = 0) {
                for t `{sensors >[2]/dev/null|grep -e '^Physical' \
                                                -e '^Package' -e '^Core' \
                                |cut -d: -f2|cut -d\( -f1|sed 's/+//g' \
                                |sed 's/°C//g'} {
                        tsum = `($tsum+$t)
                        tcnt = `($tcnt+1)
                }
                for r `{sensors >[2]/dev/null|grep -e '^fan'|cut -d: -f2 \
                                |sed 's/RPM.*$//g'} {
                        if {!~ $r 0} {
                                fsum = `($fsum+$r)
                                fcnt = `($fcnt+1)
                        }
                }
                ~ $fcnt 0 && fcnt = 1
                printf 'avg. %5.1f°C; avg. %5d RPM'\n \
			`($tsum/$tcnt) `($fsum/$fcnt)
        }
}

fn %track-file {
	# Return path of currently playing music track.
	result `` \n {cmus-remote -C status|grep '^file'|cut -d' ' -f2-}
}

fn %fullscreen-window-present {
	# Return true if a fullscreen window is present.
	let (sizes = `{xwininfo -root -children|grep '^ \+0x' \
		|sed 's/^ \+0x[0-9a-f]\+ \("[^"]\+"\|([^)]\+)\): ([^)]*)  //' \
							|cut -d+ -f1}) {
		result <={~ `%primary-display-size $sizes}
	}
}
