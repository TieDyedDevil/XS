fn %only-vt {
	# Throw an error if not running on a virtual terminal.
	~ `tty /dev/tty* || throw error %only-vt 'Only in vt'
}

fn %pt-in-rect {|x y l t r b|
	# Return true if point (x y) is in rectangle (l t r b).
	if {$x :ge $l && $x :le $r && $y :ge $t && $y :le $b} {true} \
	else {false}
}

fn %ignore-error {|body|
	# Ignore error exception thrown by body.
	catch {|e| !~ $e(1) error && throw $e} {$body}
}

fn %is-mobile {
	# Return true if system chassis is "mobile".
	let (chassis = `{cat /sys/devices/virtual/dmi/id/chassis_type}) {
		if {{$chassis :ge 8} && {$chassis :le 16}} {true} else {false}
	}
}

fn %multiple-displays {
	# Return true if multiple displays are connected.
	let (count = 0) {
		for e /sys/class/drm/*/edid {
			!~ `{cat $e|wc -c} 0 && count = `($count+1)
		}
		result <={!~ $count 0 1}
	}
}

fn %video-resolution {|file|
	# Display the resolution of video file.
	ffprobe -v error -select_streams v:0 -show_entries \
		stream=width,height -of csv=s=x:p=0 $file
}

fn %aspect {|h v std|
	# Given horizontal and vertical resolution, return display aspect
	# ratio, adjusted for standard usage unless specified as false.
	# Assumes square pixels.
	let ((ra _)= <={%rational `(1.0*$h/$v) 30}) {
		if {result $std} {
			switch $ra (
				64/27 {result 21:9}
				43/18 {result 21:9}
				24/10 {result 21:9}
				{result `{echo $ra|tr / :}}
			)
		} else {result `{echo $ra|tr / :}}
	}
}

fn %thermal {
	# Print average of temperatures and fan speeds.
        let (tcnt = 0; tsum = 0; fcnt = 0; fsum = 0) {
                for t `{sensors >[2]/dev/null|grep -e '^Physical' \
                                                -e '^Package' -e '^Core' \
                                |cut -d: -f2|cut -d\( -f1|sed 's/+//g' \
                                |sed 's/°C//g'} {
                        tsum = `($tsum+$t)
                        tcnt = `($tcnt+1)
                }
                for r `{sensors >[2]/dev/null|grep -e '^fan'|cut -d: -f2 \
                                |sed 's/RPM.*$//g'} {
                        if {!~ $r 0 N/A} {
                                fsum = `($fsum+$r)
                                fcnt = `($fcnt+1)
                        }
                }
                ~ $fcnt 0 && fcnt = 1
                printf 'avg. %5.1f°C; avg. %5d RPM'\n \
			`($tsum/$tcnt) `($fsum/$fcnt)
        }
}

fn %platform {
	# Return platform ID and version.
	result <={~~ `{cat /etc/os-release \
				|grep -o -e '^ID=.*$' -e '^VERSION_ID=.*$' \
				|tr -d "} \
			ID=* VERSION_ID=*}
}

fn %rot13 {|*|
	# Return simple (de)obfuscation.
	result `{echo $*|tr N-ZA-Mn-za-m A-Za-z}
}

fn %linepower {
	# Return true if the computer is on AC power.
	let (AC = /sys/class/power_supply/AC) {
		if {! access -d $AC} {
			true
		} else if {~ `{cat $AC/online} 1} {
			true
		} else false
	}
}
