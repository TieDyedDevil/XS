fn ag {|*|
	.d 'Search tree for pattern in files'
	.c 'alias'
	.a '[ag_OPTIONS] PATTERN [DIRECTORY]'
	/usr/bin/ag --pager='less -RFX' $*
}
fn avis {|*|
	.d 'Edit w/ APL key bindings'
	.c 'alias'
	.a '[vis_OPTIONS|FILE]...'
	akt vis $*
}
fn c {
	.d 'Clear screen'
	.c 'alias'
	clear
}
fn calc {|*|
	.d 'Evaluate arithmetic expression'
	.c 'alias'
	nickle -e $*
}
fn la {|*|
	.c 'alias'
	ls -a $*
}
fn ll {|*|
	.c 'alias'
	ls -lh $*
}
fn load {
	.d '1/5/15m loadavg; proc counts; last PID'
	.c 'alias'
	cat /proc/loadavg
}
fn ls {|*|
	.c 'alias'
	/usr/bin/ls --color=auto $*
}
fn lt {|*|
	.c 'alias'
	ls -lhtr $*
}
fn mutt {|*|
	.c 'alias'
	# mutt won't override st colors
	env TERM=st /usr/bin/mutt $*
}
fn net {
	.d 'Network status'
	.c 'system'
	nmcli --fields name,type,device \
		connection show --active
}
fn on {
	.d 'List console logins'
	.c 'alias'
	who -Huw
}
fn open {|*|
	.c 'alias'
	xdg-open $*
}
fn p {
	.d 'Pulse Audio mixer'
	.c 'alias'
	pamixer
}
fn remake {
	.d 'Remake K source projects as needed'
	.c 'alias'
	sudo -E /usr/local/bin/xs -c 'cd /usr/local/src; ./remake'
}
fn svis {|*|
	.d 'Edit file under sudo'
	.c 'alias'
	.a '[vis_OPTIONS|FILE] ...'
	sudo /usr/local/bin/vis $*
}
fn upgrade {
	.d 'Upgrade Fedora packages'
	.c 'alias'
	sudo dnf upgrade -y --refresh
}
fn whats {|*|
	.c 'alias'
	/usr/bin/whatis $*
}
fn xaos {|*|
	.d 'Fractal explorer'
	.c 'alias'
	let (dr) {
		if {~ $DISPLAY ()} {dr = aa} else {dr = 'GTK+ Driver'}
		/usr/bin/xaos -driver $dr $*
	}
}
fn zathura {|*|
	.d 'Document viewer'
	.c 'alias'
	xembed -e /usr/bin/zathura $* >/dev/null >[2=1]
}
