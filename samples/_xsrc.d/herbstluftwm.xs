fn bari {
	.d 'Status bar indicator description'
	.c 'wm'
	.r 'barre boc em hc mons osd wmb'
	%only-X
	~/.config/herbstluftwm/panel.xs legend color|less -RFXi
}
fn barre {
	.d 'Status bar restart'
	.c 'wm'
	.r 'bari boc em hc mons osd wmb'
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
	.r 'bari barre em hc mons osd wmb'
	%only-X
	unwind-protect {$*} {printf %c \a}
}
fn em {|*|
	.d 'Enable monitors'
	.a 'internal|external  # first and second in xrandr list'
	.a 'both'
	.c 'wm'
	.r 'bari barre boc hc mons osd wmb'
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
	.r 'bari barre boc em mons osd wmb'
	%only-X
	herbstclient $*
}
fn mons {|rects|
	.d 'List or define monitors'
	.a 'WxH+X+Y ...  # define logical monitors'
	.a '(none)  # list physical and logical monitors'
	.c 'wm'
	.r 'bari barre boc em hc osd wmb'
	%only-X
	if {!~ $rects ()} {
		for r $rects {
			<<<$r grep -q '^[0-9]\{1,5\}x[0-9]\{1,5\}' \
					^'+[0-9]\{1,5\}+[0-9]\{1,5\}$' \
				|| throw error mons 'invalid rect: '^$r
		}
		herbstclient set_monitors $rects
		barre
	} else {
		let (xrinfo; rect; size; w; h; diag; f; xres; dpi; _) {
			for m `{xrandr|grep '^[^ ]\+ connected .* [^ ]\+ ' \
					^'x [^ ]\+$' |cut -d' ' -f1} {
				xrinfo = `{xrandr|grep \^^$m^' '}
				rect = `{echo $xrinfo \
						|grep -o '[0-9]\+x[0-9]\+' \
							^'+[0-9]\++[0-9]\+'}
				size = <={%argify `{echo $xrinfo \
						|grep -o '[^ ]\+ x [^ ]\+$' \
						|tr -d ' '}}
				(w h) = <={~~ $size *mmx*mm}
				# 0 .. 0.3999... truncates
				# 0.4?... .. 0.9?... is ½
				diag = `{nickle -e \
					'sqrt('^$w^'**2+'^$h^'**2)/25.4+.1'}
				(diag f) = <={~~ $diag *.*}
				{~ $f 5* 6* 7* 8*} && \
					diag = `{printf %s%s $diag ½}
				xres = `{echo $xrinfo \
					|grep -o '^[^ ]\+ .* [0-9]\+x'}
				xres = <={~~ $xres *x}
				if {~ $w 0} {
					dpi = 0
				} else {
					dpi = `(25.4*$xres/$w)
					(dpi _) = <={~~ $dpi *.*}
				}
				echo $m $rect $size $diag^" $dpi^ppi
			}
			echo -- '--'
			herbstclient list_monitors|sed 's/ with [^[]\+//' \
				|sed 's/\[FOCUS\]/ 🖵/'
		} |column -t -R2,4,5
	}
}
fn osd {|msg|
	.d 'Display message on OSD'
	.a 'MESSAGE...'
	.c 'wm'
	.r 'bari barre boc em hc mons wmb'
	%only-X
	let (fl = /tmp/panel.fifos) {
		for f `{access -f $fl && cat $fl} {
			(_ k) = <={~~ $f *-*-osdmsg}
			!~ $k () && echo $msg >/tmp/panel-^$k^-osdmsg
		}
	}
}
fn wmb {
	.d 'List WM bindings'
	.c 'wm'
	.r 'bari barre boc em hc mons osd'
	%only-X
	herbstclient list_keybinds|column -t|less -FXSi
}
