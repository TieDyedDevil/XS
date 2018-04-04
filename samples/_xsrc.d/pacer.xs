fn pacer {|*|
	.d 'Hourly stretch reminder'
	.a '[off]'
	.c 'system'
	let (pspid = ~/.pacer-startup.pid) {
		if {~ $* off} {
			if {access -f $pspid} {
				echo 'Stopped during initial wait'
				pkill -g `{cat $pspid}
				rm -f $pspid
			} else {
				echo 'Stopped during operation'
				let (pacer_pid = `{pgrep -f \
						'notify-send pacer'}) {
					!~ $pacer_pid () && pkill -g $pacer_pid
				}
			}
		} else {
			let (minute; initwait; lead = 10) {
				minute = `{date +%M}
				initwait = `(60-$lead-$minute)
				~ $initwait -* && initwait = `(60+$initwait)
				echo First in $initwait minutes
				sleep `(60*$initwait)
				let (fn-work = {sleep `(60*(60-$lead))}; \
					fn-prompt = {notify-send pacer \
						'Time to stretch!'}; \
					fn-pause = {sleep `(60*$lead)}) {
					{while true {prompt; pause; work}}
				} &
			} &
			echo $apid > $pspid
		}
	}
}
