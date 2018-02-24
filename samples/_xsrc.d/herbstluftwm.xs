fn bari {
	.d 'Status bar indicator description'
	.c 'wm'
	.r 'barre boc dual em hc mons osd quad wmb'
	%only-X
	~/.config/herbstluftwm/panel.xs legend color|less -RFXi
}
fn barre {
	.d 'Status bar restart'
	.c 'wm'
	.r 'bari boc dual em hc mons osd quad wmb'
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
	.r 'bari barre dual em hc mons osd quad wmb'
	%only-X
	unwind-protect {$*} {printf %c \a}
}
fn dual {|*|
	.d 'Divide focused monitor'
	.a 'horizontal|vertical'
	.c 'wm'
	.r 'bari barre boc em hc mons osd quad wmb'
	let ((xo yo w h) = `{hc monitor_rect}; \
			ml = `{hc list_monitors|cut -d' ' -f2}) {
		let (hw = `($w/2); hh = `($h/2); \
				cmr = $w^x^$h^+^$xo^+^$yo; sm; nml) {
			if {~ $* <={%prefixes vertical}} {
				sm = $hw^x^$h^+^$xo^+^$yo \
					$hw^x^$h^+^`($xo+$hw)^+$yo
			} else if {~ $* <={%prefixes horizontal}} {
				sm = $w^x^$hh^+^$xo^+^$yo \
					$w^x^$hh^+^$xo ^+^`($yo+$hh)
			}
			for m $ml {
				if {~ $m $cmr} {
					nml = $nml $sm
				} else {nml = $nml $m}
			}
			hc set_monitors $nml
		}
	}
	barre
}
fn em {|*|
	.d 'Enable monitors'
	.a 'internal|external  # first and second in xrandr list'
	.a 'both'
	.c 'wm'
	.r 'bari barre boc dual hc mons osd quad wmb'
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
	.r 'bari barre boc dual em mons osd quad wmb'
	%only-X
	herbstclient $*
}
fn mons {|rects|
	.d 'List or define monitors'
	.a 'WxH+X+Y ...  # define logical monitors'
	.a '(none)  # list physical and logical monitors'
	.c 'wm'
	.r 'bari barre boc dual em hc osd quad wmb'
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
	.r 'bari barre boc dual em hc mons quad wmb'
	%only-X
	let (fl = /tmp/panel.fifos) {
		for f `{access -f $fl && cat $fl} {
			(_ k) = <={~~ $f *-*-osdmsg}
			!~ $k () && echo $msg >/tmp/panel-^$k^-osdmsg
		}
	}
}
fn quad {
	.d 'Divide focused monitor'
	.c 'wm'
	.r 'bari barre boc dual em hc mons osd wmb'
	let ((xo yo w h) = `{hc monitor_rect}; \
			ml = `{hc list_monitors|cut -d' ' -f2}) {
		let (hw = `($w/2); hh = `($h/2); \
				cmr = $w^x^$h^+^$xo^+^$yo; nml) {
			for m $ml {
				if {~ $m $cmr} {
					nml = $nml \
						$hw^x^$hh^+^$xo^+^$yo \
						$hw^x^$hh^+^`($xo+$hw)^+$yo \
						$hw^x^$hh^+^$xo^+^`($yo+$hh) \
						$hw^x^$hh^+^`($xo+$hw) \
								^+^`($yo+$hh)
				} else {nml = $nml $m}
			}
			hc set_monitors $nml
		}
	}
	barre
}
fn wmb {
	.d 'List WM bindings'
	.c 'wm'
	.r 'bari barre boc dual em hc mons osd quad'
	%only-X
	herbstclient list_keybinds|column -t|less -FXSi
}
