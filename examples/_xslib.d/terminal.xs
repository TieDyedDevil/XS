fn %with-quit {|*|
	# Run command with q key bound to send SIGINT.
	stty intr q
	unwind-protect {
		$*
	} {
		stty intr \^C
	}
}

fn %without-echo {|cmd|
	# Disable terminal echo while evaluating cmd.
	unwind-protect {
		< /dev/tty $&tctl noecho
		$cmd
	} {
		< /dev/tty $&tctl echo
	}
}

fn %without-cursor {|*|
	# Run command with terminal cursor hidden.
	.ci
	unwind-protect {
		$*
	} {
		.cn
	}
}

fn %get-cursor-position {
	# Query ANSI terminal for its cursor position (row col).
	let (c; d; row = 0; col = 0; state = 0) {
		unwind-protect {
			</dev/tty $&tctl raw; </dev/tty $&tctl noecho
			printf \e[6n
			escape {|fn-break| while true {
				c = <={$&getc </dev/tty}
				if {~ $state 0} {
					~ $c [ && state = 1
				} else if {~ $state 1} {
					if {~ $c \;} {
						state = 2
					} else {
						row = `($row*10+$c)
					}
				} else if {~ $state 2} {
					~ $c R && break
					col = `($col*10+$c)
				}
			}}
		} {
			</dev/tty $&tctl canon; </dev/tty $&tctl echo
		}
		result $row $col
	}
}

fn %with-bracketed-paste-mode {|cmd|
	# Enable terminal bracketed-paste mode while evaluating cmd.
	unwind-protect {
		printf \e'[?2004h'
		$cmd
	} {
		printf \e'[?2004l'
	}
}

fn %withrgb {|bghex fghex text|
	# Display text with Truecolor bg/fg colors.
	# Hex values are prefixed with `#` and have six digits.
	let (fn-hrgb2d = {|hex|
			map {|*| echo $*|awk --non-decimal-data \
				'{printf "%d ", $1}'} \
				`{%rgbhex $hex|sed -E 's/\#(..)(..)(..)/' \
					^'0x\1 0x\2 0x\3/'}}) { \
		printf \e'[48;2;%03d;%03d;%03dm'\e'[38;2;%03d;%03d;%03dm%s' \
			`{hrgb2d $bghex} `{hrgb2d $fghex} $^text
	}
}

fn %preserving-title {|cmd|
	# Run a command, preserving the title of the focused window.
	if {!~ $DISPLAY ()} {
		let (__t = `{xdotool getwindowfocus getwindowname}) {
			unwind-protect {
				$cmd
			} {
				title $__t
			}
		}
	} else {
		$cmd
	}
}

fn %with-application-keypad {|cmd|
	# Run command with keypad application keys.
	printf \e\=
	unwind-protect {$cmd} {printf \e\>}
}

fn %no-with-terminal {|cmd|
	# Run command, preventing any %with-terminal command from
	# instantiating a terminal.
	local (NO_WITH_TERMINAL = 1) {$cmd}
}

fn %with-terminal {|title cmd|
	# Run command, spawning a titled terminal if necessary.
	# Sets WITH_TERMINAL variable if terminal was spawned.
	if {!~ $SSH_TTY () || !~ $SSH_CONNECTION ()} {
		{$cmd}
	} else {
		local (DISPLAY = :0) {
			if {!~ $NO_WITH_TERMINAL () || tty -s} {$cmd} else {
				exec env WITH_TERMINAL=$pid stq -t $title \
								xs -c {$cmd}
			}
		}
	}
}

fn %wt-pager {|lessopts|
	# Use in conjuction with %with-terminal to provide a
	# pager to hold transient output.
	if {~ $WITH_TERMINAL ()} {env LESSSECURE=1 less -eiRXF $lessopts} \
	else {env LESSSECURE=1 less -eiRX $lessopts}
}

fn %terminal-of-pid {|pid|
	# Print window ID of terminal running given PID.
	let (ppid; comm; cpid) {
		until {{~ $ppid 1} || {~ $comm st}} {
			(ppid comm cpid) = `{ps -o ppid=,comm=,pid= $pid}
			pid = $ppid
		}
		if {~ $comm st} {echo $cpid}
	}
}
