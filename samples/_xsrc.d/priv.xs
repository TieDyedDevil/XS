fn atop {|*|
	.d 'Advanced system & process monitor'
	.a '[atop_OPTIONS]'
	.c 'priv'
	%with-terminal sudo /usr/bin/atop $*
}
fn iotop {|*|
	.c 'priv'
	%with-terminal sudo /usr/sbin/iotop $*
}
fn iptraf-ng {|*|
	.c 'priv'
	%with-terminal sudo /usr/sbin/iptraf-ng $*
}
fn nethogs {|*|
	.c 'priv'
	%with-terminal sudo /usr/sbin/nethogs $*
}
fn panel {|*|
	.d 'Query/set Intel backlight intensity'
	.a '[1..100]'
	.c 'priv'
	if {access -d /sys/class/backlight/intel_backlight} {
		let (b = $*; bp = /sys/class/backlight/intel_backlight; mb) {
			mb = `{cat $bp/max_brightness}
			if {~ $#* 0} {
				let (ab; p; i; f) {
					ab = `{cat $bp/brightness}
					p = `(1.0*$ab*100/$mb)
					(i f) = <={~~ `($p+0.5) *.*}
					echo $i
				}
			} else {
				if {~ $* 0} {b = 1}
				sudo su -c 'echo '^`($mb*$b/100)^' >'^$bp \
					^'/brightness'
			}
		}
	} else {throw error panel 'no Intel backlight'}
}
fn powertop {|*|
	.c 'priv'
	%with-terminal sudo /usr/sbin/powertop $*
}
%cfn {!~ <={access -1n radeontop $path} ()} radeontop {|*|
	.c 'priv'
	%with-terminal sudo /usr/sbin/radeontop $*
}
fn remake {
	.d 'Remake K source projects as needed'
	.c 'priv'
	.r 'upgrade'
	sudo -E /usr/local/bin/xs -c 'cd /usr/local/src; ./remake'
}
fn svis {|*|
	.d 'Edit file under sudo'
	.a '[vis_OPTIONS|FILE] ...'
	.c 'priv'
	sudo /usr/local/bin/vis $*
}
fn tiptop {|*|
	.c 'priv'
	%with-terminal sudo /usr/bin/tiptop $*
}
fn upgrade {
	.d 'Upgrade Fedora packages'
	.c 'priv'
	.r 'remake'
	sudo dnf upgrade -y --refresh
}
fn wavemon {|*|
	.c 'priv'
	%with-terminal sudo /usr/bin/wavemon $*
}
