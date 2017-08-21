if {~ $SSH_TTY ()} {
	pgrep -xc pulseaudio >/dev/null || {
		pulseaudio --start
		pacmd load-module module-switch-on-connect
		pacmd load-module module-dbus-protocol
	}
	pgrep -xc mpd >/dev/null || {
		rm -f ~/.mpd/mpd.log
		mpd
	}
	~/.monitor/monitor
}
