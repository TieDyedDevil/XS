fn atop {|*|
	.d 'Advanced system & process monitor'
	.a '[atop_OPTIONS]'
	.c 'priv'
	.f 'wrap'
	%with-terminal atop sudo /usr/bin/atop $*
}

fn bpftrace {|*|
	.d 'High-level eBPF tracing'
	.a '[bpftrace_OPTIONS]'
	.c 'priv'
	.f 'wrap'
	sudo /usr/bin/bpftrace $*
}

fn conspy {|*|
	.d 'Linux console spy'
	.a '[conspy_OPTIONS]'
	.c 'priv'
	.f 'wrap'
	%with-terminal conspy sudo /usr/bin/conspy $*
}

fn ftop {|*|
	.d 'Show progress of open files'
	.a '[ftop_OPTIONS]'
	.c 'priv'
	.f 'wrap'
	%with-terminal ftop sudo /usr/bin/ftop $*
}

fn flowtop {|*|
	.d 'Top network flows'
	.a '[flowtop_OPTIONS]'
	.c 'priv'
	.f 'wrap'
	%with-terminal flowtop sudo /usr/sbin/flowtop -G $*
}

fn intel_gpu_time {|*|
	.d 'Show CPU and GPU utilization of command'
	.a 'COMMAND'
	.c 'priv'
	.f 'wrap'
	sudo /usr/bin/intel_gpu_time $*
}

fn intel_gpu_top {|*|
	.d 'Show Intel GPU tasks'
	.a '[intel_gpu_top_OPTIONS]'
	.c 'priv'
	.f 'wrap'
	%with-terminal intel_gpu_top sudo /usr/bin/intel_gpu_top $*
}

fn iotop {|*|
	.d 'I/O monitor'
	.a '[iotop_OPTIONS]'
	.c 'priv'
	.f 'wrap'
	%with-terminal iotop sudo /usr/sbin/iotop $*
}

fn iptraf-ng {|*|
	.d 'IP LAN monitor'
	.a '[iptraf-ng_OPTIONS]'
	.c 'priv'
	.f 'wrap'
	%with-terminal iptraf-ng sudo /usr/sbin/iptraf-ng $*
}

fn latencytop-tui {
	.d 'Latency monitor'
	.c 'priv'
	.f 'wrap'
	%with-terminal latencytop-tui sudo /usr/sbin/latencytop-tui
}

fn mandb {|*|
	.d 'Update man page index caches'
	.a '[mandb_OPTIONS]'
	.c 'priv'
	.f 'wrap'
	sudo /usr/bin/mandb $*
}

fn mount {|*|
	.d 'Mount a filesystem'
	.a '[mount_OPTIONS]'
	.c 'priv'
	.f 'wrap'
	sudo /usr/bin/mount $*
}

fn nethogs {|*|
	.d 'Per-process network bandwidth'
	.a '[nethogs_OPTIONS]'
	.c 'priv'
	.f 'wrap'
	%with-terminal nethogs sudo /usr/sbin/nethogs $*
}

fn netsniff-ng {|*|
	.d 'Packet sniffer'
	.a '[netsniff-ng_OPTIONS]'
	.c 'priv'
	.f 'wrap'
	%with-terminal netsniff-ng %with-quit sudo /usr/sbin/netsniff-ng $*
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

fn perf {|*|
	.d 'Peformance analysis tools'
	.a '[perf_OPTIONS]'
	.a '(none)  # top --hierarchy'
	.c 'priv'
	.f 'wrap'
	%with-terminal perf {
		if {~ $*(1) list} {
			/usr/bin/perf $* | less -iRFX
		} else if {~ $#* 0} {
			sudo /usr/bin/perf top --hierarchy
		} else {
			sudo /usr/bin/perf $*
		}
	}
}

fn powertop {|*|
	.d 'Power-consumption analysis and management'
	.a '[powertop_OPTIONS]'
	.c 'priv'
	.f 'wrap'
	%with-terminal powertop sudo /usr/sbin/powertop $*
}

%cfn {%have radeontop} radeontop {|*|
	.d 'Show Radeon GPU utilization'
	.a '[radeontop_OPTIONS]'
	.c 'priv'
	.f 'wrap'
	%with-terminal radeontop sudo /usr/sbin/radeontop $*
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
	sudo /usr/local/bin/vis +'set theme light-16' $*
}

fn tiptop {|*|
	.d 'Display hardware performance counters'
	.a '[tiptop_OPTIONS]'
	.c 'priv'
	.f 'wrap'
	%with-terminal tiptop sudo /usr/bin/tiptop $*
}

fn umount {|*|
	.d 'Unmount a filesystem'
	.a '[umount_OPTIONS]'
	.c 'priv'
	.f 'wrap'
	sudo /usr/bin/umount $*
}

fn updatedb {|*|
	.d 'Update mlocate database'
	.a '[updatedb_OPTIONS]'
	.c 'priv'
	.f 'wrap'
	sudo /usr/bin/updatedb $*
}

fn upgrade {
	.d 'Upgrade Fedora packages'
	.c 'priv'
	.r 'remake'
	sudo dnf upgrade -y --refresh
}

fn wavemon {|*|
	.d 'Wireless-network monitor'
	.a '[wavemon_OPTIONS]'
	.c 'priv'
	.f 'wrap'
	%with-terminal wavemon sudo /usr/bin/wavemon $*
}
