fn :q {
	.d 'exit'
	.c 'alias'
	exit
}

fn abook {|*|
	.d 'Address book'
	.a '[abook_OPTIONS]'
	.c 'alias'
	.f 'wrap'
	%with-terminal abook /usr/bin/abook $*
}

fn ag {|*|
	.d 'Search tree for pattern in files'
	.a '[ag_OPTIONS] PATTERN [DIRECTORY]'
	.c 'alias'
	.f 'wrap'
	/usr/bin/ag --pager='less -iRFX' $*
}

fn c {
	.d 'Clear screen'
	.c 'alias'
	clear
}

fn cal {|*|
	.d 'Calendar'
	.a '[cal_OPTIONS]'
	.c 'alias'
	.f 'wrap'
	let (opt = -3) {
		!~ $#* 0 && opt = $*
		%with-terminal cal {
			/usr/bin/cal --color=always $opt | %wt-pager
		}
	}
}

fn calc {|*|
	.d 'Evaluate arithmetic expression'
	.a '[nickle_EXPRESSION]'
	.c 'alias'
	if {~ $#* 0} {
		%with-terminal calc nickle
	} else {
		nickle -e $*
	}
}

fn centerim {|*|
	.d 'IM client'
	.a '[centerim_OPTIONS]'
	.c 'alias'
	%with-terminal centerim {/usr/bin/centerim $*}
}

fn cgdb {|*|
	.d 'TUI GDB'
	.a '[cgdb_OPTIONS]'
	.c 'alias'
	.f 'wrap'
	env INPUTRC=/dev/null /usr/bin/cgdb $*
}

fn dclock {|*|
	.d '24-hour digital clock'
	.c 'alias'
	.a '[xclock_OPTIONS]'
	.f 'wrap'
	result %with-terminal
	/usr/bin/xclock -digital -brief -face 'Noto Sans Mono-23' \
							-geometry +0 $*
}

fn df {|*|
	.d 'Show free disk space'
	.c 'alias'
	.a '[df_OPTIONS]'
	.f 'wrap'
	%with-terminal df {/usr/bin/df -h $*|%wt-pager}
}

fn dict {|*|
	.d 'Dictionary'
	.a '[dict_OPTIONS]'
	.c 'alias'
	.f 'wrap'
	%with-terminal dict {/usr/bin/dict $* >[2=1]| %wt-pager}
}

fn gct {|*|
	.d 'git commits today'
	.a '[git-log_OPTIONS]'
	.c 'alias'
	git log --stat --since=midnight $*
}

fn gft {|*|
	.d 'git files today'
	.a '[git-log_OPTIONS]'
	.c 'alias'
	git log --name-status --since=midnight --pretty=format: $* \
						|sort|uniq|grep -v '^$'
}

fn gnofract4d {|*|
	.d '2D fractal generator'
	.a '[gnofract4d_OPTIONS]'
	.c 'alias'
	.f 'wrap'
	result %with-terminal
	/usr/bin/gnofract4d $* >[2]/dev/null
}

fn hexer {|*|
	.d 'Binary file editor'
	.a '[hexer_OPTIONS]'
	.c 'alias'
	%with-terminal hexer {/usr/bin/hexer $*}
}

fn htop {|*|
	.d 'Interactive process viewer'
	.a '[htop_OPTIONS]'
	.c 'alias'
	.f 'wrap'
	%with-terminal htop /usr/bin/htop $*
}

fn keyview2 {|*|
	.d 'Keystroke and mouse button monitor'
	.a '[keyview2_OPTIONS]'
	.c 'alias'
	result %with-terminal
	/usr/local/bin/keyview2 $*
}

fn mb2 {|*|
	.d '3D fractal generator'
	.a '[mandelbulber2_OPTIONS]'
	.a 'dt|cd  # size for desktop or CD cover'
	.c 'alias'
	.f 'wrap'
	result %with-terminal
	unwind-protect {
		let (geomopt) {
			if {~ $* dt} {
				geomopt = -r `%primary-display-size
				* = $*(2 ...)
			} else if {~ $* cd} {
				# Really 1400x1400; so what?
				geomopt = -r 1440x1440
				* = $*(2 ...)
			}
			nice -n 5 mandelbulber2 $geomopt $*
		}
	} {
		rmdir --ignore-fail-on-non-empty ~/mandelbulber
	}
}

fn mutt {|*|
	.d 'Email client'
	.a '[mutt_OPTIONS]'
	.c 'alias'
	.f 'wrap'
	%with-terminal mutt {
		# mutt won't override st colors
		env TERM=st /usr/bin/mutt $*
		# update xbiff immediately
		%refresh-xbiff
	}
	true
}

fn n {
	.d 'Edit ~/notes'
	.c 'alias'
	.f 'wrap'
	%with-terminal n vis ~/notes
}

fn newsboat {|*|
	.d 'RSS client'
	.a '[newsboat_OPTIONS]'
	.c 'alias'
	.f 'wrap'
	%with-terminal newsboat /usr/bin/newsboat $*
}

fn noice {|*|
	.d 'Files explorer'
	.c 'alias'
	.a '[noice_OPTIONS]'
	.f 'wrap'
	%with-terminal noice /usr/local/bin/noice $*
}

fn oclock {|*|
	.d '12-hour clock'
	.c 'alias'
	.a '[oclock_OPTIONS]'
	.f 'wrap'
	result %with-terminal
	/usr/bin/oclock -transparent -bd gray -fg white $*
}

fn pal {|*|
	.d 'Event calendar'
	.a '[pal_OPTIONS]'
	.c 'alias'
	.f 'wrap'
	%with-terminal pal {
		/usr/bin/pal --color $*|%wt-pager
	}
}

fn pinfo {|*|
	.d 'Info browser'
	.a '[pinfo_OPTIONS]'
	.c 'alias'
	%with-terminal pinfo /usr/bin/pinfo $*
}

fn poweroff {|*|
	.d 'poweroff'
	.a '[poweroff_OPTIONS]'
	.c 'alias'
	result %with-terminal
	/usr/sbin/poweroff $*
}

fn powwow {|*|
	.d 'MUD client'
	.a '[powwow_OPTIONS]'
	.c 'alias'
	%with-terminal powwow {/usr/bin/powwow $*}
}

fn printers {
	.d 'Configure printers'
	.c 'alias'
	web http://localhost:631
}

fn reboot {
	.d 'reboot'
	.a '[reboot_OPTIONS]'
	.c 'alias'
	result %with-terminal
	/usr/sbin/reboot $*
}

fn recordmydesktop {|*|
	.d 'Desktop video recorder'
	.a '[recordmydesktop_OPTIONS]'
	.a 'stop  # finish current recording'
	.c 'alias'
	result %with-terminal
	if {~ $* stop} {
		pkill recordmydesktop
	} else {
		pgrep -cq recordmydesktop || /usr/local/bin/recordmydesktop $*
	}
}

fn se {|*|
	.d 'Screen-oriented ed'
	.a '[se_OPTIONS]'
	.c 'alias'
	%with-terminal se {/usr/local/bin/se $*}
}

fn seren {|*|
	.d 'VOIP conferencing'
	.a '[seren_OPTIONS]'
	.c 'alias'
	%with-terminal seren {/usr/bin/seren $*}
}

fn slrn {|*|
	.d 'NNTP newsreader'
	.a '[slrn_OPTIONS]'
	.c 'alias'
	%with-terminal slrn {/usr/bin/slrn $*}
}

fn slrnpull {|*|
	.d 'NNTP spooler'
	.a '[slrnpull_OPTIONS]'
	.c 'alias'
	%with-terminal slrnpull {sudo slrnpull -h free.xsusenet.com $*}
}

fn sticky {|*|
	.d 'Leave a "sticky note" in ~'
	.a 'DIRECTORY|FILE|TEXT...'
	.c 'alias'
	.f 'wrap'
	if {~ $#* 0} {
		.usage sticky
	} else {
		if {access -d -- $*} {
			ln -s `` \n {cd $*; pwd} ~
		} else if {access -f -- $*} {
			ln -s `` \n {cd `{dirname $*}; pwd}^/ \
							^`` \n {basename $*} ~
		} else {
			ln -s $^* ~
		}
	}
}

fn sysmon {
	.d 'View Monitorix stats'
	.c 'alias'
	web http://localhost:8080/monitorix
}

fn top {|*|
	.d 'Display processes'
	.a '[top_OPTIONS]'
	.c 'alias'
	.f 'wrap'
	%with-terminal top /usr/bin/top $*
}

fn tshark {|*|
	.d 'Wireshark network analyzer'
	.a '[tshark_OPTIONS]'
	.c 'alias'
	.f 'wrap'
	%with-terminal tshark /usr/bin/tshark $*
}

fn weechat {|*|
	.d 'Chat client'
	.a '[weechat_OPTIONS]'
	.c 'alias'
	%with-terminal weechat /usr/bin/weechat $*
}

fn whois {|*|
	.d 'Retrieve domain name info'
	.a '[whois_OPTIONS]'
	.c 'alias'
	.f 'wrap'
	%with-terminal whois {/usr/bin/whois $* | %wt-pager}
}

fn wn {|*|
	.d 'Wordnet'
	.a '[wn_OPTIONS]'
	.c 'alias'
	.f 'wrap'
	%with-terminal wn {/usr/bin/wn $* | %wt-pager}
}

fn xclipboard {
	.d 'Navigate clipboard selections'
	.c 'alias'
	result %with-terminal
	/usr/bin/xclipboard -w
}

fn xclock {|*|
	.d 'Xorg analog clock'
	.a '[xclock_OPTIONS]'
	.c 'alias'
	result %with-terminal
	/usr/bin/xclock $*
}

fn xdot {
	.d 'Dot file viewer'
	.a '[xdot_OPTIONS]'
	.c 'alias'
	result %with-terminal
	/usr/bin/xdot $*
}

fn xfd {|*|
	.d 'Font display'
	.a 'FONT_NAME'
	.c 'alias'
	result %with-terminal
	if {!/usr/bin/xfd -fn $^*} {/usr/bin/xfd -fa $^*} >[2]/dev/null
}

fn xmag {|*|
	.d 'X magnifier'
	.a '[xmag_OPTIONS]'
	.c 'alias'
	result %with-terminal
	/usr/bin/xmag $*
}

fn yapet {|*|
	.d 'Password safe'
	.a '[yapet_OPTIONS]'
	.c 'alias'
	.f 'wrap'
	%with-terminal yapet {/usr/bin/yapet $*}
}
