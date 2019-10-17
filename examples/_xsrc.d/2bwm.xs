fn wmb {
	.d 'Display window manager key bindings'
	.c 'wm'
	%with-terminal wmb {
		{cat <<'EOF'
[These bindings assume a US keyboard.]
WINDOW ========================
Mod4+tab			activate next window on workspace
Shift+Mod4+tab			activate previous window on workspace
Mod4+q				kill window
Shift+Mod4+{h,j,k,l}		resize window
Shift+Control+Mod4+{h,j,k,l}	resize window, slow
Mod4+{h,h,k,l}			move window
Control+Mod4+{h,j,k,l}		move window, slow
Mod4+{y,u,g,b,n}		move window to preset location
Control+Mod4+g			center window horizontally
Shift+Mod4+g			center window vertically
Mod1+Mod4+{h,j,k,l}		move window to screen edge
Mod4+home			grow window
Mod4+end			shrink window
Mod4+x				maximize window (toggle)
Mod4+m				maximize window vertically (toggle)
Shift+Mod4+m			maximize window horizontally (toggle)
Shift+Mod4+{y,u}		maximize window vertically at left/right edge
Shift+Mod4+{b,n}		maximize window horizontally at top/bottom edge
Shift+Control+Mod4+{y,u}	fold/unfold window vertically
Shift+Control+Mod4+{b,n}	fold/unfold window horizontally
Mod4+r				raise/lower window (toggle)
Mod4+o				original window size
Mod4+i				hide window
Shift+Mod4+i			unhide all windows
Mod4+t				window always on top
Mod4+a				window ignores kill
POINTER =======================
Mod4+{left,up,down,right}	move pointer
Shift+Mod4+{left,up,down,right}	move pointer, fast
Control+Mod4+Left		left button click
Control+Mod4+Down		middle button click
Control+Mod4+Right		right button click
Control+Mod4+Up+Release		expose pointer
Shift+Control+Mod4+Up+Release	home pointer
Control+Alt+Mod4+Up+Release	refocus window under pointer
WORKSPACE =====================
Mod4+{1-9,0}			change workspace
Shift+Mod4+{1-9,0}		move window to workspace
Mod4+{v,c}			next/previous workspace
Shift+Mod4+{v,c}		move window to next/previous workspace
Mod4+f				make window visible on all workspaces (toggle)
SCREEN ========================
Mod4+{period,comma}		move window to next/previous screen
ACTIVITY ======================
Mod4+w				program menu
Mod4+Return			terminal
Control+Mod4+Return		persistent terminal
Mod4+slash			macro menu
Control+Mod4+slash		create macro
Shift+Mod4+slash		delete macro
Mod4+Escape			refresh status bar and reload key bindings
Mod4+semicolon			window menu - all windows
Shift+Mod4+semicolon		window menu - without hidden windows
Mod4+z				lock screen
Shift+Mod4+z			transparent lock screen
Control+Mod4+z			eye candy
Mod4+Multi_key			screen capture
Shift+Mod4+Multi_key		select region capture
Mod4+d				rotate wallpaper
Shift+Mod4+d			remove wallpaper
Control+Mod4+d			recolor wallpaper
Mod1+Mod4+d			blackout wallpaper
Control+Mod1+Mod4+d		startup wallpaper
Mod4+e				rotate photo backdrop
CLIPBOARD =====================
Mod4+apostrophe			copy primary selection to clipboard
REPORT ========================
Mod4+grave			report workspace number
Mod4+s				report battery status
Mod4+backslash			report date and time
Mod4+bracketright		report mail status
Mod4+bracketleft		report persistent sessions
Mod4+BackSpace			report memory availability
Mod4+equal			report load average
Mod4+minus			report thermal status
Mod4+p				report playing track
Shift+Mod4+p			display cover art of playing track

[Media key bindings for keyboards which
 have these.]
Menu				program menu
XF86Sleep			lock screen
Shift+XF86Sleep			transparent lock screen
Mod4+XF86Sleep			eye candy
XF86AudioPlay			music play/pause
Shift+XF86AudioPlay		music seek to start of track
XF86AudioNext			music next track
Shift+XF86AudioNext		music skip 20 seconds forward
XF86AudioPrev			music previous track
Shift+XF86AudioPrev		music skip 20 seconds backward
XF86AudioRaiseVolume		increase volume 1 dB
XF86AudioLowerVolume		decrease volume 1 dB
XF86AudioMute			mute audio output
Control+XF86AudioMute		audio mixer
Mod4+XF86AudioMute		bluetooth control
Shift+Mod1+XF86AudioMute	audio spectrum display
Mod1+XF86AudioMute		audio equalizer
XF86AudioMicMute		mute microphone

[These keys function on a host, but are
 not passed by virt-viewer(1) to a guest.
 Use the "Send key" menu.]
Control+Alt+BackSpace		restart WM, followed by autologin
Control+Alt+F1			switch from console
Control+Alt+{F2..F12}		switch to console
EOF
		} | less -iRFX
	}
}
