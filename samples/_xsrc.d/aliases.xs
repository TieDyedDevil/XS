fn ag {|*|
	.d 'Search tree for pattern in files'
	.a '[ag_OPTIONS] PATTERN [DIRECTORY]'
	.c 'alias'
	/usr/bin/ag --pager='less -RFX' $*
}
fn apropos {|*|
	.d 'Find man pages by keyword'
	.a '[apropos_OPTIONS] KEYWORD...'
	.c 'alias'
	/usr/bin/apropos -l $*|less -FXS
}
fn atop {|*|
	.d 'Advanced system & process monitor'
	.a '[atop_OPTIONS]'
	.c 'alias'
	sudo /usr/bin/atop $*
}
fn avis {|*|
	.d 'Edit w/ APL key bindings'
	.a '[vis_OPTIONS|FILE]...'
	.c 'alias'
	akt vis $*
}
fn c {
	.d 'Clear screen'
	.c 'alias'
	clear
}
fn calc {|*|
	.d 'Evaluate arithmetic expression'
	.a 'nickle_EXPRESSION'
	.c 'alias'
	~ $#* 0 || nickle -e $*
}
fn d {
	.d 'Date/time (local and UTC)'
	.c 'alias'
	date; date -u
}
fn la {|*|
	.c 'alias'
	.r 'll ls lt'
	ls -a $*
}
fn latest {
	.d 'List latest START processes for current user'
	.c 'alias'
	ps auk-start_time -U $USER|less -FX
}
fn ll {|*|
	.c 'alias'
	.r 'la ls lt'
	ls -lh $*
}
fn load {
	.d '1/5/15m loadavg; proc counts; last PID'
	.c 'alias'
	cat /proc/loadavg
}
fn ls {|*|
	.c 'alias'
	.r 'la ll lt'
	/usr/bin/ls --group-directories-first -v --color=auto $*
}
fn lt {|*|
	.c 'alias'
	.r 'la ll ls'
	ls -lhtr $*
}
fn mutt {|*|
	.c 'alias'
	# mutt won't override st colors
	env TERM=st /usr/bin/mutt $*
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
	.r 'upgrade'
	sudo -E /usr/local/bin/xs -c 'cd /usr/local/src; ./remake'
}
fn svis {|*|
	.d 'Edit file under sudo'
	.a '[vis_OPTIONS|FILE] ...'
	.c 'alias'
	sudo /usr/local/bin/vis $*
}
fn sysmon {
	.d 'View Monitorix stats'
	.c 'alias'
	web http://localhost:8080/monitorix
}
fn topc {
	.d 'List top %CPU processes'
	.c 'alias'
	.r 'topm topr topt topv'
	ps auxk-%cpu|head -11
}
fn topm {
	.d 'List top %MEM processes'
	.c 'alias'
	.r 'topc topr topt topv'
	ps auxk-%mem|head -11
}
fn topr {
	.d 'List top RSS processes'
	.c 'alias'
	.r 'topc topm topt topv'
	ps auxk-rss|head -11
}
fn topt {
	.d 'List top TIME processes'
	.c 'alias'
	.r 'topc topm topr topv'
	ps auxk-time|head -11
}
fn topv {
	.d 'List top VSZ processes'
	.c 'alias'
	.r 'topc topm topr topt'
	ps auk-vsz|head -11
}
fn treec {|*|
	.d 'Display filesystem tree'
	.a 'DIRECTORY'
	.c 'alias'
	tree --du -hpugDFC $* | less -RFX
}
fn upgrade {
	.d 'Upgrade Fedora packages'
	.c 'alias'
	.r 'remake'
	sudo dnf upgrade -y --refresh
}
fn zathura {|*|
	.d 'Document viewer'
	.c 'alias'
	xembed -e /usr/bin/zathura $* >/dev/null >[2=1]
}
