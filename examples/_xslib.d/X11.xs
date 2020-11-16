fn %only-X {
	# Throw an error if not running under X.
	~ $DISPLAY () && throw error %only-X 'Only under X'
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
				echo $xo $yo `($xs+$xo-1) `($ys+$yo-1)
			}
		}
	}
}

fn %primary-display {
	# Print primary display name.
	# This does not poll the display hardware for changes.
	xrandr --current|grep 'connected primary'|cut -d' ' -f1
}

fn %primary-display-size {
	# Print primary display size as WIDTHxHEIGHT.
	# This does not poll the display hardware for changes.
	xrandr --current|grep 'connected primary'|cut -d' ' -f4|cut -d+ -f1
}

fn %window-bounds {
	# Print active window boundaries as LEFT TOP RIGHT BOTTOM.
	let ((xo yo xs ys b) = `{xwininfo -int -id `{xdotool getactivewindow} \
			|grep 'Absolute\|Width\|Height\|Border'|cut -d: -f2}) {
		echo $xo $yo `($xs+$xo+2*$b) `($ys+$yo+2*$b)
	}
}

fn %window-screen-region {
	# Return the screen region (LEFT TOP RIGHT BOTTOM) of the largest
	# portion of the active window.
	escape {|fn-return| {let ((xl yt xr yb) = `%window-bounds) {
		for sr `` \n %screen-regions {
			let ( \
			(l t r b) = `{echo $sr}; \
			xo = `(($xl+$xr)/2); \
			yo = `(($yt+$yb)/2) \
			) {
				if {%pt-in-rect $xo $yo $l $t $r $b} {
					return $l $t $r $b
				}
			}
		}
	}}}
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

fn %fullscreen-window-present {
	# Return true if a fullscreen window is present on the primary display.
	let (sizes = `{xwininfo -root -children|grep '^ \+0x' \
		|sed 's/^ \+0x[0-9a-f]\+ \("[^"]\+"\|([^)]\+)\): ([^)]*)  //' \
							|cut -d+ -f1}) {
		result <={~ `%primary-display-size $sizes}
	}
}

fn %window-group {
	# Return window group number
	result `{/usr/bin/xprop -root|grep '^_NET_CURRENT_DESKTOP' \
							|cut -d' ' -f3}
}

