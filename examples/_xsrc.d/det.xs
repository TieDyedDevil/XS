fn det {|*|
	.d 'Detach'
	.a 'NAME [COMMAND [ARGS...]]'
	.a '-g [COMMAND [ARGS...]]  # generate name'
	.a '-p  # print name of this session'
	.a '(none)  # list attach commands for all sessions'
	.i 'Without COMMAND, attach to the existing session NAME or start'
	.i 'a new session with $SHELL as the COMMAND.'
	.c 'system'
	if {~ $*(1) -* && !~ $*(1) -g -p} {throw error det 'option?'}
	if {~ $* ()} {
		{
			pgrep -a dtach|cut -d' ' -f4|uniq|sort \
				|sed 's/^\/tmp\//det /' \
				|tee /dev/stderr \
				|[2]{~ `{wc -l} 0 && echo 'No det' >[1=2]}
		}|less -iRFX
		true
	} else if {~ $*(1) -p} {
		let (tpid = $pid) {
			while {!~ <={tpid = `{ps -o ppid= $tpid}} 1} {
				if {~ `{ps -o comm= $tpid} dtach} {
					ps -o command= $tpid|cut -d' ' -f3
				}
			}|uniq|sed 's/^\/tmp\///'
		}
	} else {
		if {~ $*(1) -g} {
			* = `{mktemp -u -p '' det.XXXXXXXXX \
						|sed 's/^\/tmp\///'} \
				$*(2 ...)
		}
		~ $#* 1 && * = $*(1) xs
		let (tpid = $pid) {
			while {!~ <={tpid = `{ps -o ppid= $tpid}} 1} {
				if {~ `{ps -o comm= $tpid} dtach} {
					throw error det 'no nesting!'
				}
			}
		}
		%preserving-title {
			title det $*(1)
			dtach -A /tmp/^$*(1) -r winch $*(2 ...)
		}
	}
}
