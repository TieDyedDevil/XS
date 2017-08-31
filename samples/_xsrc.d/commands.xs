fn battery {
	.d 'Show battery status'
	.c 'system'
	let (pspath = /sys/class/power_supply; full = 0; curr = 0; \
		ef; ec; en) {
		for d ($pspath/BAT?) {
			access -d $d && {
				ef = `{cat $d/energy_full_design}
				ec = `{cat $d/energy_full}
				en = `{cat $d/energy_now}
				full = `($full+$ec)
				curr = `($curr+$en)
				printf '%s %s (%.2f)'\n \
					`{basename $d} `{cat $d/status} \
					`(1.0*$ec/$ef)
			}
		}
		!~ $curr 0 && printf '%.1f%%'\n `(100.0*$curr/$full)
	}
}
fn cookie {
	.d 'Fortune'
	.c 'system'
	let (subjects = art computers cookie definitions goedel \
			humorists literature people pets platitudes \
			politics science wisdom) {
		fortune -n 200 -s $subjects
	}
}
fn cs {|*|
	.d 'List compose sequences'
	.a '[-a]  # show all variations'
	.c 'system'
	%with-read-lines <{grep '^<Multi_key>' \
				/usr/share/X11/locale/en_US.UTF-8/Compose | \
		grep -v -e '<dead' -e '<kana_' -e '<hebrew_' -e '<Arabic_' \
			-e '<Cyrillic_' -e '<Greek_' -e '<Ukrainian_' \
			-e '<KP_' -e '<ae>' -e '<AE>' -e '<ezh>' -e '<EZH>' \
			-e '<underbar>' -e '<.\?acute>' -e '<.\?tilde>' \
			-e '<.\?ring>' -e '<.\?diaeresis>' -e '<.\?grave>' \
			-e '<.\?cedilla>' -e '<.\?horn>' -e '<.\?circumflex>' \
			-e '<.\?breve>' -e '<.\?macron>' -e '<.\?acute>' \
			-e '<.\?caron>' -e '<.\?slash>' -e '<.\?oblique>' \
			-e '<U\([0-9A-Fa-f]\)\+>' \
		| grep -v -e '"   \b\(ascii[^ ]\+\|brace[^ ]\+\|at\|bar\|' \
			^'apostrophe\|numbersign\|bracket\(left\|right\)\) ' \
		| sed 's/^\(.\+ # \). . \(.\+\)$/\1\2/' \
		| if {~ $*(1) -a} cat else {uniq -f 4} \
	} {|*|
		kf = /usr/include/X11/keysymdef.h
		ksym = `{echo $*|sed 's|^[^:]\+:[[:space:]]\+"[^"]\+"' \
				^'[[:space:]]\+\([^ ]\+\).*$|\1|'}
		if {grep -q 'U[[:xdigit:]]\+\b' <{echo $ksym}} {
			echo $*
		} else {
			ksd = `{grep 'XK_'^$ksym^'\b' $kf}
			if {~ $#ksd 0} {
				echo $*
			} else {
				kuc = `{echo $ksd \
					|grep -o ' *U+[[:xdigit:]]\+ ' \
					|tr -d +|head -1}
				echo $*|sed 's|^\([^:]\+: \+"[^"]\+" \+\)' \
					^'[[:alpha:]]\+\(.*\)$|\1'^$kuc^'\2|'
			}
		}
	} | expand | awk -F: '{printf "%-48.48s:%s\n", ' \
				^'gensub(/^(.*) +$/, "\\1", "g", $1), ' \
				^'gensub(/ +/, " ", "g", $2)}' \
		| env LESSUTFBINFMT='*s?' less -SFX
}
fn d {
	.d 'Date/time (local and UTC)'
	.c 'system'
	date
	date -u
}
fn dl-clean {
	.d 'Remove advertising asset files left behind by WebKit browser'
	.c 'system'
	let (pat = *^(\; \? \% \=)^* zrt_lookup.html*; files) {
		files = `{ls $pat >[2]/dev/null|sort|uniq}
		!~ $#files 0 && rm -I -v $files
	}
}
fn doc {|*|
	.d 'pushd to documentation directory of package'
	.a 'PACKAGE_NAME_GLOB'
	.c 'system'
	if {!~ $* ()} {
		let (pl) {
			pl = `{find -L /usr/share/doc /usr/local/share/doc \
				-mindepth 1 -maxdepth 1 -type d \
				|grep -i '/usr.*/share/doc.*'^$*}
			if {~ $#pl 1} {
				pushd $pl
			} else if {~ $#pl ???*} {
				throw error doc 'more than 99 matches'
			} else {
				for p ($pl) {echo `{basename $p}}
				echo $#pl matches
			}
		}
	}
}
fn import-abook {|*|
	.d 'Import vcard to abook'
	.a 'VCARD_FILE'
	.c 'system'
	mv ~/.abook/addressbook ~/.abook/addressbook-OLD
	abook --convert --infile $* --informat vcard --outformat abook \
		--outfile ~/.abook/addressbook
	chmod 600 ~/.abook/addressbook
}
fn latest {
	.d 'List latest START processes for current user'
	.c 'system'
	ps auk-start_time -U $USER|less -FX
}
fn lock {
	.d 'Lock screen'
	.c 'system'
	if {~ $DISPLAY ()} {
		vlock
	} else {
		~/.local/bin/lock
	}
}
fn lpman {|man|
	.d 'Print a man page'
	.a 'PAGE'
	.c 'system'
	env MANWIDTH=80 man $man | sed 's/^.*/    &/' \
		| lpr -o page-top=60 -o page-bottom=60 \
			-o page-left=60 -o lpi=8 -o cpi=12
}
fn lpmd {|md|
	.d 'Print a markdown file'
	.a 'FILE'
	.c 'system'
	markdown $md | w3m -T text/html -cols 80 | sed 's/^.*/    &/' \
		| lpr -o page-top=60 -o page-bottom=60 \
			-o page-left=60 -o lpi=8 -o cpi=12
}
fn luc {
	.d 'List user commands'
	.c 'system'
	echo `.ab^'* xs'^`.an
	vars -f | grep -o '^fn-[^ ]\+' | cut -d- -f2- | grep '^[a-z]' \
		| tr \n \  | par 72j
	echo `.ab^'* bin'^`.an
	ls ~/bin | tr \n \  | par 72j
}
fn mamel {
	.d 'List installed MAME games'
	.c 'system'
	ls /usr/share/mame/roms|sed 's/\.zip$//'|column
}
fn mdv {|*|
	.d 'Markdown file viewer'
	.a 'MARKDOWN_FILE'
	.c 'system'
	if {!~ $#* 1 || !access -f $*} {
		throw error mdv 'usage: mdv MARKDOWN_FILE'
	} else {
		markdown -f fencedcode $* | w3m -X -T text/html -no-mouse \
			-no-proxy -o confirm_qq=0 -o document_root=`pwd
	}
}
fn mons {
	.d 'List attached monitors recognized by bspwm'
	.c 'system'
	grep -f <{map {|*| echo \^$*} `{bspc query -M --names}} <{xrandr} \
		|sed 's/ \(dis\)\?connected / /'|sed 's/ (.*) / /' \
		|sed 's/mm x /x/'|awk '{printf("%s\t%9s\t%s\n", $1, $3, $2)}'
}
fn name {|*|
	.d 'Set prompt text and terminal title.'
	.a '[NAME]'
	.c 'system'
	if {~ $* ()} {
		prompt ''
		title `{echo $TERM|sed 's/-256color.*//'}
	} else {
		prompt $*
		title $*
	}
}
fn noise {|*|
	.d 'Audio noise generator'
	.a '[white|pink|brown [LEVEL_DB]]'
	.c 'system'
	let (pc = $*(1); pl = $*(2); color = pink; pad = -6; level = -20; \
		volume) {
		~ $pc brown && {color = brown; pad = 0}
		~ $pc pink && {color = pink; pad = -6}
		~ $pc white && {color = white; pad = -12}
		if {~ $pl -* || ~ $pl 0} {level = $pl} else {level = -20}
		volume = `($level + $pad)
		play </dev/zero -q -t s32 -r 22050 -c 2 - synth $color^noise \
			tremolo 0.05 30 vol $volume dB
	}
}
fn o {
	.d 'List open windows per desktop'
	.c 'system'
	for d `{bspc query -D --names} {
		let (wl = `{bspc query -N -n .window -d $d}; vf) {
			if {!~ $wl ()} {
				echo Desktop $d
				for w $wl {
					if {~ `{bspc query -N -n $w^.hidden} \
						()} {
							vf = visible
						} else {
							vf = hidden\ 
						}
					printf \ \ [%s\ %s]\t%s\n \
						$vf $w `` \n {xtitle $w}
				}
			}
		}
	} | less -RFX
}
fn oc {
	.d 'Onscreen clock'
	.c 'system'
	%with-quit {
		%without-cursor {
			watch -t -n 1 -p banner \`date +%A%n%T%n%x\`
		}
	}
}
fn panel {|*|
	.d 'Query/set Intel backlight intensity'
	.a '[1..100]'
	.c 'system'
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
fn pn {
	.d 'Users with active processes'
	.c 'system'
	ps haux|cut -d' ' -f1|sort|uniq
}
fn pp {|*|
	.d 'Prettyprint xs function'
	.a 'NAME'
	.c 'system'
	catch {|e|
		echo 'not a function'
	} {%pprint $*; printf \n} | less -FXS
}
fn prs {|*|
	.d 'Display process info'
	.a '[-f] [prtstat_OPTIONS] NAME'
	.c 'system'
	!~ $* () && {
		let (pgrep_option = -x) {
			{~ $*(1) -f} && {
				pgrep_option = $*(1)
				* = $*(2 ...)
			}
			let (pids = `{pgrep $pgrep_option $*}) {
				if {!~ $pids ()} {
					for pid $pids {
						!~ $#pids 1 && echo '========'
						prtstat $pid
					} | less -FX
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
	.c 'system'
	.pu $*|awk '{if ($14 != "?") print}'|less -FX
}
fn pu {|*|
	.d 'ps for user'
	.a '[[-fFCyM] USERNAME]'
	.c 'system'
	.pu $*|less -FX
}
fn screensaver {|*|
	.d 'Query/set display screensaver enable'
	.a '[on|off]'
	.a '(none)  # show current'
	.c 'system'
	let (error = false) {
		if {~ $DISPLAY ()} {
			if {!~ `tty */tty*} {throw error screensaver 'not a tty'}
			if {~ $#* 0} {
				timeout = `{cat /sys/module/kernel/parameters/consoleblank}
				if {~ $timeout 0} {echo Off} \
				else {echo On}
			} else {
				switch $* (
				on {setterm -blank 15 -powerdown 15 >>/dev/tty}
				off {setterm -blank 0 -powerdown 0 >>/dev/tty}
				{error = true})
			}
		} else {
			if {~ $#* 0} {
				let (timeout) {
					timeout = `{xset q|grep timeout \
						|awk '{print $2}'}
					if {~ $timeout 0} {echo Off} \
					else {echo On}
				}
			} else {
				switch $* (
				on {xset +dpms; xset s on}
				off {xset -dpms; xset s off}
				{error = true})
			}
		}
		if $error {throw error screensaver 'on or off'}
	}
}
fn startwm {
	.d 'Start X window manager'
	.c 'system'
	if {!~ $DISPLAY ()} {
		throw error startwm 'already running'
	} else if {!~ `tty *tty*} {
		throw error startwm 'run from console'
	} else {
		cd; exec startx -- -logverbose 0 >~/.startx.log >[2=1]
	}
}
fn swapm {
	.d 'Exchange positions of monitors'
	.c 'system'
	let ((m1 m2) = `{
		grep -f <{map {|*| echo \^$*} `{bspc query -M --names}} \
			<{xrandr} \
			|sed 's/ \(dis\)\?connected / /'|sed 's/ (.*) / /' \
			|awk '{printf("%s\t%s\n", $1, $2)}' \
			|sort -n -t+ -k2|cut -f1}) {
			!~ $m2 () && {
				xrandr --output $m2 --left-of $m1
				echo $m2 $m1
			}
	}
}
fn sysmon {
	.d 'View Monitorix stats'
	.c 'system'
	web http://localhost:8080/monitorix
}
fn topc {
	.d 'List top %CPU processes'
	.c 'system'
	ps auxk-%cpu|head -11
}
fn topm {
	.d 'List top %MEM processes'
	.c 'system'
	ps auxk-%mem|head -11
}
fn topr {
	.d 'List top RSS processes'
	.c 'system'
	ps auxk-rss|head -11
}
fn topt {
	.d 'List top TIME processes'
	.c 'system'
	ps auxk-time|head -11
}
fn topv {
	.d 'List top VSZ processes'
	.c 'system'
	ps auk-vsz|head -11
}
fn thermal {
	.d 'Summarize system thermal status'
	.c 'system'
	sensors >[2]/dev/null | grep -e '^Physical' -e '^Core' -e '^fan' \
		| sed 's/ *(.*$//'
}
fn title {|*|
	.d 'Set terminal title'
	.a '[TITLE]'
	.c 'system'
	$&echo -n \e]0\;^$^*^\a
}
fn tsmwd {
	.d 'Return to tsm working directory'
	.c 'system'
	if {!~ $TSMWD ()} {cd $TSMWD; echo $TSMWD} else echo .
}
fn tss {|*|
	.d 'Terminal screen size utility'
	.a '-u  # update ROWS and COLUMNS environment vars'
	.a '-d  # delete ROWS and COLUMNS environment vars'
	.a '-q  # display ROWS and COLUMNS environment vars'
	.a '(none)  # show terminal size'
	.c 'system'
	switch $* (
	-d {COLUMNS = ; ROWS =}
	-u {(ROWS COLUMNS) = (`{tput lines} `{tput cols})}
	-q {var COLUMNS ROWS}
	{})
	~ $* () && {printf '%sx%s'\n `{tput cols} `{tput lines}}
}
fn u2o {|*|
	.d 'Unicode text to octal escapes'
	.a 'TEXT'
	.c 'system'
	{echo -n $*|hexdump -b|grep -Eo '( [0-7]+)+'|tr ' ' \\\\}
}
fn uh {
	.d 'Undo history'
	.c 'system'
	!~ $history () && {
		let (li = `{cat $history|wc -l}) {
			history -d $li >/dev/null
			history -d `($li-1)
		}
	}
}
fn ulu {|*|
	.d 'Unicode lookup'
	.a 'PATTERN'
	.c 'system'
	let (ud = /usr/share/unicode/ucd/UnicodeData.txt) {
		%with-read-lines <{egrep -i -o '^[0-9a-f]{4,};[^;]*' \
						^$*^'[^;]*;' $ud} {|l|
			let ((hex desc) = <={~~ $l *\;*\;}) {
				hex = `{printf %8s $hex|tr ' ' 0}
				uni = `{eval echo '\U'^$hex >[2]/dev/null}
				if {!result $bqstatus} {uni = !UTF-8}
				!~ $desc \<control\> && \
					printf %s\tU+%s\t%s\n $uni $hex $desc
			}
		} | env LESSUTFBINFMT=*n!PRINT less -FXS
	}
}
fn wallpaper {|*|
	.d 'Set wallpaper'
	.a '[-m MONITOR] FILE-OR-DIRECTORY'
	.a '[-m MONITOR] DELAY_MINUTES DIRECTORY'
	.a '(none)  # restore root window'
	.c 'system'
	if {~ $DISPLAY ()} {
		throw error wallpaper 'X only'
	} else {
		local (pageopt = $pageopt) {
			let (geom; mon; monopt) {
				if {~ $*(1) -m} {
					mon = $*(2)
					monopt = $*(1 2); monopt = $^monopt
					* = $*(3 ...)
					geom = `{grep \^$mon <{xrandr}| \
						cut -d' ' -f3}
				}
				!~ $geom () && pageopt = -page $geom
				switch $#* (
				1 {	let (f) {
						access -f $* && f = $*
						access -d $* && wallpaper \
							`{find -L $* \
							\( -name '*.jpg' \
							-o -name '*.png' \) \
							|shuf|head -1}
						!~ $f () && {
							display -window root \
								$pageopt $f
						}
					}
				}
				2 {	let (m = $*(1); d = $*(2); \
						p = 'while true {wallpaper '; \
						f = 'while true \{wallpaper') {
						access -d $d && {
							pkill -f $f
							setsid xs -c \
							$p^$monopt^' ' \
							^$d^'; sleep ' \
							^`($m*60)^'}' &
						}
					}
				}
				{	pkill -f 'while true \{wallpaper'
					xsetroot -solid 'Slate Gray'
				})
			}
		}
	}
}
fn where {
	.d 'Summarize user, host, tty, shell pid and working directory'
	.c 'system'
	printf '%s@%s[%s;%d]:%s'\n \
		$USER `{hostname -s} <={~~ `tty /dev/*} $pid `pwd
}
