fn em {|*|
	.d 'Enable one monitor'
	.a '[external|internal]  # first and second in xrandr list'
	.a '(none) # first in xrandr list'
	.c 'system'
	%only-X
	let (i; hc = herbstclient; \
		mnl = `{xrandr|grep '^[^ ]\+ connected' \
			|cut -d' ' -f1}) {
		if {~ $#mnl 1} {throw error em 'One monitor'}
		i = 0
		for m $mnl {
			if {xrandr|grep -q '^'^$m^' .*[^ ]\+ x [^ ]\+$'} {
				hc rename_monitor $i '' >[2]/dev/null
			}
			i = `($i+1)
		}
		hc lock
		if {~ $* <={%prefixes external}} {
			xrandr --output $mnl(1) --off \
				--output $mnl(2) --auto --primary
			hc rename_monitor 0 $mnl(2)
		} else {
			xrandr --output $mnl(1) --auto --primary \
				--output $mnl(2) --off
			hc rename_monitor 0 $mnl(1)
		}
		hc reload
		hc unlock
	}
	# Since we've changed monitor size, remove wallpaper.
	pkill -f 'while true \{wallpaper'
	xsetroot -solid 'Slate Gray'
}
fn hc {|*|
	.c 'alias'
	herbstclient $*
}
fn mons {
	.d 'List active monitors'
	.c 'system'
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
			dpi = `(25.4*$xres/$w)
			(dpi _) = <={~~ $dpi *.*}
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
fn wmb {
	.d 'List WM bindings'
	.c 'alias'
	herbstclient list_keybinds|column -t|less -FXSi
}
