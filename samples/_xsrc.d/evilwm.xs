fn q {
	.d 'Quit wm'
	.c 'wm'
	%confirm n 'Quit wm' && pkill evilwm
}
fn wmb {
	.d 'List wm bindings'
	.c 'wm'
	less -fiFX <{cat <<EOF
Mod4+button1	move window
Mod4+button2	resize window
Mod4+button3	lower window
Mod4+return	spawn new terminal
Mod4+escape	delete window
Mod4+Shift+escape force kill window
Mod4+insert	lower window
Mod4+{h,j,k,l}	move window left,down,up,right
Mod4+Shift+{h,j,k,l}  resize window left,down,up,right
Mod4+{y,u,b,n}	move window to top-left,top-right,bottom-left,bottom-right
Mod4+i		show window information
Mod4+equals	toggle maximize window vertically
Mod4+x		toggle maximize window
Mod4+d		toggle dock(s) visibility
Mod4+f		toggle fix window to all desktops
Mod4+{1..8}	switch to desktop 1..8
Mod4+left	previous desktop
Mod4+right	next desktop
Mod4+a		last-viewed desktop
Mod4+tab	cycle next window
Mod4+slash	bury pointer
Mod4+period	center pointer
Mod4+p		report battery state
Mod4+m		mpc toggle
Mod4+e		equalizer toggle
Mod4+w		wallpaper cycle
Mod4+s		screen capture
Mod4+r		run program
EOF
	}
}
