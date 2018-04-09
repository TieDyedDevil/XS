fn latest {
	.d 'List latest START processes for current user'
	.c 'process'
	%view-with-header 1 <{ps auk-start_time -U $USER} latest
}
fn load {
	.d '1/5/15m loadavg; proc counts; last PID'
	.c 'process'
	cat /proc/loadavg
}
fn pn {
	.d 'Users with active processes'
	.c 'process'
	ps haux|cut -d' ' -f1|sort|uniq
}
fn prs {|*|
	.d 'Display process info'
	.a '[-f] [prtstat_OPTIONS] NAME'
	.c 'process'
	if {~ $#* 0} {
		.usage prs
	} else {
		let (pgrep_option = -x) {
			{~ $*(1) -f} && {
				pgrep_option = $*(1)
				* = $*(2 ...)
			}
			let (pids = `{pgrep $pgrep_option $*}) {
				if {!~ $pids ()} {
					for pid $pids {
						!~ $#pids 1 && echo '========'
						ps -o command= -p $pid
						echo
						prtstat $pid
					} | less -iFX
				} else {
					echo 'not found'
				}
			}
		}
	}
}
fn pt {|*|
	.d 'ps for user; only processes with terminal'
	.a '[[-fFcyM] USERNAME]'
	.c 'process'
	.r 'pu'
	%view-with-header 1 <{.pu $*|awk '{if ($14 != "?") print}'} pt
}
fn pu {|*|
	.d 'ps for user'
	.a '[[-fFCyM] USERNAME]'
	.c 'process'
	.r 'pt'
	%view-with-header 1 <{.pu $*} pu
}
fn topc {
	.d 'List top %CPU processes'
	.c 'process'
	.r 'topm topr topt topv'
	ps auxk-%cpu|head -11
}
fn topm {
	.d 'List top %MEM processes'
	.c 'process'
	.r 'topc topr topt topv'
	ps auxk-%mem|head -11
}
fn topr {
	.d 'List top RSS processes'
	.c 'process'
	.r 'topc topm topt topv'
	ps auxk-rss|head -11
}
fn topt {
	.d 'List top TIME processes'
	.c 'process'
	.r 'topc topm topr topv'
	ps auxk-time|head -11
}
fn topv {
	.d 'List top VSZ processes'
	.c 'process'
	.r 'topc topm topr topt'
	ps auk-vsz|head -11
}
