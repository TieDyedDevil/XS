if {~ $SSH_TTY ()} {
	pulseaudio --check || {
		pulseaudio --start >[2]/dev/null
		until {pulseaudio --check} {sleep 0.5}
		pacmd load-module module-switch-on-connect
		pacmd load-module module-dbus-protocol
	}
	pgrep -xc mpd >/dev/null || {
		rm -f ~/.mpd/mpd.log
		mpd
	}
}
