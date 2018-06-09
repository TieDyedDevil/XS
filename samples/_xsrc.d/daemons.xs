if {~ $SSH_TTY ()} {
	pgrep -c pulseaudio >/dev/null || {
		until {pgrep -c pulseaudio >/dev/null} {
			pulseaudio --start
			sleep 0.1
		}
		pacmd load-module module-switch-on-connect
		pacmd load-module module-dbus-protocol
	}
	pgrep -xc mpd >/dev/null || {
		rm -f ~/.mpd/mpd.log
		mpd
	}
}
