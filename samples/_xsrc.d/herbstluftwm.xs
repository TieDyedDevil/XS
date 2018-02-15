fn barre {
	.d 'Status bar restart'
	.c 'wm'
	.r 'boc em hc mons osd wmb'
	%only-X
	let (hc = herbstclient) {
		hc emit_hook quit_panel
		for monitor `{hc list_monitors | cut -d: -f1} {
			setsid ~/.config/herbstluftwm/panel.xs $monitor \
				>>[2]~/.startx.log &
		}
	}
}
fn boc {|*|
	.d 'Bell on completion'
	.a 'COMMAND'
	.c 'wm'
	.r 'barre em hc mons osd wmb'
	%only-X
	unwind-protect {$*} {printf %c \a}
}
fn em {|*|
	.d 'Enable monitors'
	.a 'internal|external  # first and second in xrandr list'
	.a 'both'
	.c 'wm'
	.r 'barre boc hc mons osd wmb'
	%only-X
	let (i; hc = herbstclient; \
		mnl = `{xrandr|grep '^[^ ]\+ connected' \
			|cut -d' ' -f1}) {
		i = 0
		for m $mnl {
			if {xrandr|grep -q '^'^$m^' .*[^ ]\+ x [^ ]\+$'} {
				hc rename_monitor $i '' >[2]/dev/null
			}
			i = `($i+1)
		}
		if {~ $* <={%prefixes both}} {
			if {~ $#mnl 1} {throw error em 'one monitor'}
			xrandr --output $mnl(1) --auto --left-of $mnl(2) \
				--output $mnl(2) --auto --primary
		} else if {~ $* <={%prefixes external}} {
			if {~ $#mnl 1} {throw error em 'one monitor'}
			xrandr --output $mnl(1) --off \
				--output $mnl(2) --auto --primary
		} else if {~ $* <={%prefixes internal}} {
			xrandr --output $mnl(1) --auto --primary \
				--output $mnl(2) --off
		} else {throw error em 'which?'}
		hc lock
		hc reload
	}
	# Since we've changed monitor size, remove wallpaper.
	wallpaper
}
fn hc {|*|
	.d 'herbstclient'
	.a 'herbstclient_ARGS'
	.c 'wm'
	.r 'barre boc em mons osd wmb'
	%only-X
	herbstclient $*
}
fn mons {
	.d 'List active monitors'
	.c 'wm'
	.r 'barre boc em hc osd wmb'
	%only-X
	let (i; hc = herbstclient; xrinfo; size; w; h; diag; f; _; xres; dpi; \
		mnl = `{xrandr|grep '^[^ ]\+ connected .* [^ ]\+ x [^ ]\+$' \
			|cut -d' ' -f1}) {
		i = 0
		for m $mnl {
			hc rename_monitor $i ''
			hc rename_monitor $i $m
			i = `($i+1)
		}
		for m $mnl {
			xrinfo = `{xrandr|grep \^^$m^' '}
			size = <={%argify `{echo $xrinfo \
						|grep -o '[^ ]\+ x [^ ]\+$' \
						|tr -d ' '}}
			(w h) = <={~~ $size *mmx*mm}
			# 0 .. 0.3999... truncates
			# 0.4?... .. 0.9?... is ½
			diag = `{nickle -e 'sqrt('^$w^'**2+'^$h^'**2)/25.4+.1'}
			(diag f) = <={~~ $diag *.*}
			{~ $f 5* 6* 7* 8*} && diag = `{printf %s%s $diag ½}
			xres = `{echo $xrinfo|grep -o '^[^ ]\+ .* [0-9]\+x'}
			xres = <={~~ $xres *x}
			if {~ $w 0} {
				dpi = 0
			} else {
				dpi = `(25.4*$xres/$w)
				(dpi _) = <={~~ $dpi *.*}
			}
			join -1 7 -o1.1,1.7,1.2,2.2,2.3,1.4,1.5,1.8 \
				<{hc list_monitors|grep "$m"} \
				<{printf "%s"\ %s\ %s"\;%dppi\n \
					$m $size $diag $dpi}
		} \
			| awk '{sub(/^.:/, sprintf("%c", 0x2460+$1)); print}' \
			| sed 's/",/"/' \
			| sed 's/"\([^" ]\+\)"/\1/g' \
			| sed 's/tag\s/tag:/' \
			| sed 's/\[FOCUS\]/🖵/' \
			| column -t
	}
}
fn osd {|msg|
	.d 'Display message on OSD'
	.a 'MESSAGE...'
	.c 'wm'
	.r 'barre boc em hc mons wmb'
	%only-X
	let (m; fl; f; _; k) {
		for m `{herbstclient list_monitors|cut -d: -f1} {
			fl = /tmp/panel-^$m^-fifos
			for f `{access -f $fl && cat $fl} {
				(_ k) = <={~~ $f *-*-osdmsg-^$m}
				!~ $k () && echo $msg \
					>/tmp/panel-^$k^-osdmsg-^$m
			}
		}
	}
}
fn wmb {
	.d 'List WM bindings'
	.c 'wm'
	.r 'barre boc em hc mons osd'
	%only-X
	herbstclient list_keybinds|column -t|less -FXSi
}
