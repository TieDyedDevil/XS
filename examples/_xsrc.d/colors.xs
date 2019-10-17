fn colors {|*|
	.d 'Display terminal colors'
	.a '[8|16|256|true]  # ANSI'
	.a '[-X [xs_filter_thunk]]  # X11; filter on $r, $g, $b and $d'
	.c 'system'
	%with-terminal colors {
	let ( \
	fn-palette_colors = {|n|
	    fgb = `{tput setaf 0}
	    fgw = `{tput setaf 7}
	    c = 0
	    while {$c :lt $n} {
	        printf '%s %s%3d %s%3d ' `{tput setab $c} $fgb $c $fgw $c
	        {`($c % 8) :eq 7} && {printf \e'[m'\n}
	        c = `($c + 1)
	    }
	    printf %s `{tput sgr0}
	} \
	) {
	let ( \
	fn-colors_8 = {palette_colors 8}; \
	fn-colors_16 = {palette_colors 16}; \
	fn-colors_256 = {palette_colors 256}; \
	fn-bgcolor = {|r g b| printf \e'[48;2;%d;%d;%dm' $r $g $b}; \
	fn-rgr = {printf %s `{tput sgr0}}; \
	fn-eol = {printf \n}; \
	fn-spc = {printf ' '}; \
	fn-wheel_color = {|n|
	    h = `($n/43)
	    f = `($n-43*$h)
	    t = `($f*255/43)
	    q = `(255-$t)
	    switch $h (
	      0 {echo 255 $t 0}
	      1 {echo $q 255 0}
	      2 {echo 0 255 $t}
	      3 {echo 0 $q 255}
	      4 {echo $t 0 255}
	      5 {echo 255 0 $q}
	    )
	} \
	) {
	let ( \
	fn-rgb = {|c v|
	    switch $c (
	      r {bgcolor $v 0 0}
	      g {bgcolor 0 $v 0}
	      b {bgcolor 0 0 $v}
	      m {bgcolor $v 0 $v}
	      y {bgcolor $v $v 0}
	      c {bgcolor 0 $v $v}
	      w {bgcolor $v $v $v}
	    )
	} \
	) {
	let ( \
	fn-gradient_part = {|c s|
	    printf '%3d ' $s(1)
	    if {$s(1) :lt $s(2)} {
	        i = $s(1)
	        while {$i :le $s(2)} {
	            rgb $c $i
	            printf ' '
	            i = `($i + 1)
	        }
	    } else {
	        i = $s(1)
	        while {$i :ge $s(2)} {
	            rgb $c $i
	            printf ' '
	            i = `($i - 1)
	        }
	    }
	    rgr
	    printf ' %3d' $s(2)
	    eol
	}; \
	seg1 = 0 63; \
	seg2 = 127 64; \
	seg3 = 128 191; \
	seg4 = 255 192 \
	) {
	let ( \
	fn-gradient = {|c|
	    gradient_part $c $seg1
	    gradient_part $c $seg2
	    gradient_part $c $seg3
	    gradient_part $c $seg4
	}; \
	fn-wheel_spc = {|i|
	    if {0 :eq `($i % 43)} {
	        printf \e'[30m•'\e'[m'
	    } else {
	        printf ' '
	    }
	} \
	) {
	let ( \
	fn-wheel_part = {|s|
	    if {$s(1) :lt $s(2)} {
	        printf '>>> '
	        i = $s(1)
	        while {$i :le $s(2)} {
	            bgcolor `{wheel_color $i}
	            wheel_spc $i
	            i = `($i + 1)
	        }
	        rgr
	        printf ' >>>'
	    } else {
	        printf '<<< '
	        i = $s(1)
	        while {$i :ge $s(2)} {
	            bgcolor `{wheel_color $i}
	            wheel_spc $i
	            i = `($i - 1)
	        }
	        rgr
	        printf ' <<<'
	    }
	    eol
	} \
	) {
	let ( \
	fn-color_wheel = {
	    wheel_part $seg1
	    wheel_part $seg2
	    wheel_part $seg3
	    wheel_part $seg4
	} \
	) {
	let ( \
	fn-colors_24_bit = {
	    color_wheel
	    gradient r
	    gradient y
	    gradient g
	    gradient c
	    gradient b
	    gradient m
	    gradient w
	}; \
	fn-check_list = {
	    blacklist = linux xterm
	    for t $blacklist {
	        if {$TERM :eq $t} {
	            echo Terminal $t does not support TrueColor
	            false
	            return
	        }
	    }
	    true
	}; \
	fn-show_xcolors = {|*|
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
		}
	} \
	) {
	let ( \
	fn-dispatch = {|d|
	    switch $d (
	      8 {colors_8}
	      16 {colors_16}
	      256 {colors_256}
	      true {check_list && colors_24_bit}
	      usage
	    )
	} \
	) {
	%with-terminal colors {
	    if {$#* :eq 0} {
	        dispatch `{tput colors}
	    } else if {~ $*(1) -X} {
		show_xcolors $*(2)
	    } else {
	        dispatch $1
	    } | %wt-pager
	}
	}}}}}}}}} #let
	} # %with-terminal
}
