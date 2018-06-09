if {~ $SSH_TTY ()} {
	pgrep -c pulseaudio >/dev/null || {
		until {pgrep -c pulseaudio >/dev/null} {
			pulseaudio --start #>[2]/dev/null
			sleep 0.5
		}
		pacmd load-module module-switch-on-connect
		pacmd load-module module-dbus-protocol
	}
	pgrep -xc mpd >/dev/null || {
		rm -f ~/.mpd/mpd.log
		mpd
	}
}
