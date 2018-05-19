fn pacer {|*|
	.d 'Hourly stretch reminder'
	.a '[off]'
	.c 'wm'
	let (pspid = ~/.pacer.pid) {
		if {~ $* off} {
			if {access -f $pspid} {
				pkill -g `{cat $pspid}
				echo 'Stopped'
				rm -f $pspid
			}
		} else if {{access -f $pspid} \
				&& {kill -0 `{cat $pspid} >[2]/dev/null}} {
			echo 'Running'
		} else setsid xs -c {
			let (minute; second; initwait; lead = 3) {
				(minute second) = `{date +%M\ %S}
				initwait = `(60-$lead-$minute)
				~ $initwait -* 0 && initwait = `(60+$initwait)
				echo First in $initwait minutes
				sleep `(60*$initwait-$second)
				let (fn-work = {sleep `(60*(60-$lead))}; \
					fn-prompt = {notify-send pacer \
						'Time to stretch!'}; \
					fn-pause = {sleep `(60*$lead)}; \
					fn-go = {for i <={%range 1-5} { \
						osd .; osd ''''}}) {
					{while true {prompt; pause; go; work}}
				} &
				echo $apid > $pspid
			} &
			echo $apid > $pspid
		}
	}
}
