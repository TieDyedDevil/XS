fn ameter {
	.d 'Display audio output level'
	.c 'media'
	result %with-terminal
	stq -g 80x1 -T ameter xs -c '%without-cursor %without-echo %with-quit \
	forever {arecord -c2 -traw -fS16_LE -r44100 -vv -Vstereo \
		-d 0 /dev/null |[2] stdbuf -o0 tail -f -n+25}' &
}

fn artwork {|*|
	.d 'Display artwork for audio track'
	.a 'TRACK_FILE'
	.a '(none)  # current track'
	.c 'media'
	result %with-terminal
	let (track = $^*) {
		~ $track '' && track = <=%track-file
		~ $track () && throw error artwork 'no current/given track'
		sxiv -g 720x720 -bq `` \n {dirname $track}^/*.^(png jpg)
	}
}

fn bluetoothctl {
	.d 'Bluetooth control'
	.c 'media'
	.f 'wrap'
	%with-terminal bluetoothctl /usr/bin/bluetoothctl
}

fn cava {
	.d 'Audio spectrum display'
	.c 'media'
	.f 'wrap'
	result %with-terminal
	stq -g 80x13 -T cava /usr/bin/cava &
}

fn cmus {|*|
	.d 'Music player'
	.a '[cmus_OPTIONS]'
	.c 'media'
	.f 'wrap'
	%with-terminal cmus /usr/bin/cmus $*
}

fn e {
	.d 'Interactive Pulse Audio equalizer'
	.c 'media'
	.r 'equalizer'
	%with-terminal e {
		let ( \
		fn-gp = {
			let (pc = `{ls ~/.config/pulse/presets/*.preset \
					|xargs -d\n -n1 basename \
					|sed 's/.preset//'|wc -l}; \
			pn; ok = false) {
				until {$ok} {
					printf 'preset [1..'^$pc^'] ? '
					pn = <=read
					if {{echo $pn|grep -q '^[0-9]\+$' \
								>/dev/null \
						&& {$pn :le $pc} \
						&& {$pn :gt 0}} || ~ $pn ''} {
						ok = true
					} else {echo invalid}
				}
				result $pn
			}
		} \
		) {
		%menu 'Pulse Audio equalizer' (
			e enable {equalizer enable} C
			d disable {equalizer disable} C
			t toggle {equalizer toggle} C
			s status {equalizer status} C
			c curve {equalizer curve} C
			p presets {equalizer presets} C
			l load {
				let (p = <=gp) {
					!~ $p '' && equalizer load $p
				}
			} C
			a adjust {equalizer adjust} C
			j judge {
				let (pl; p) {
					until {~ $p ''} {
						p = <=gp
						!~ $p '' && pl = $pl $p
					}
					equalizer judge $pl
				}
			} C
			i info {equalizer info} C
			h help {cat <<EOF
e)nable
d)isable
t)oggle
s)tatus
c)urve
p)resets
l)oad PRESET
a)djust
j)udge PRESET ...
i)nfo
h)elp
q)uit
EOF
				} C
			q exit {} B
		)
		}
	}
}

fn equalizer {|*|
	.d 'Pulse Audio equalizer'
	.a '[enable|disable|toggle]'
	.a '[status|curve]'
	.a '[presets|load PRESET#|adjust]'
	.a '[judge PRESET#... # 2 to 9 presets]'
	.a '[info]'
	.c 'media'
	let (fn-filter = {grep '^Equalizer status:'|grep -o '\[.*\]' \
				|tr -d '[]'}; \
	cf = ~/.config/pulse/equalizerrc; \
	pd = ~/.config/pulse/presets
	pulseaudio-equalizer = ~/.local/bin/pulseaudio-equalizer) {
		if {~ $* <={%prefixes enable}} {
			~ `{equalizer status} enabled \
				&& $pulseaudio-equalizer disable >/dev/null
			$pulseaudio-equalizer enable | filter
			rm -f ~/.config/pulse/pending
		} else if {~ $* <={%prefixes disable}} {
			$pulseaudio-equalizer disable | filter
		} else if {~ $* <={%prefixes toggle}} {
			$pulseaudio-equalizer toggle | filter
		} else if {~ $* <={%prefixes status}} {
			$pulseaudio-equalizer status | filter
			access -f ~/.config/pulse/pending && echo pending
		} else if {~ $* <={%prefixes curve}} {
			let (bc; bands; gains) {
				bc = `{tail -n+10 $cf|head -1}
				bands = `{tail -n+11 $cf|tail -n+`($bc+1)}
				gains = `{tail -n+11 $cf|head -$bc}
				tail -n+5 $cf|head -1
				for g $gains; b $bands {
					printf '%+4.1f dB @ %''6d Hz'\n $g $b
				}
			}
		} else if {~ $* <={%prefixes presets}} {
			ls $pd^/*.preset|xargs -d\n -n1 basename \
				|sed 's/.preset//'|nl
		} else if {{~ $#* 2} && {~ $*(1) <={%prefixes load}}} {
			let (pfl = `` \n {ls $pd^/*.preset}) {
				ed -s $pfl($*(2)) <<EOF
5a
0
0
-10
10
.
w $cf
q
EOF
				touch ~/.config/pulse/pending
			# It's intentional to NOT activate the preset we just
			# loaded. We just imported a new configuration file;
			# the active settings do not change. The user gets to
			# determine an appropriate workflow.
			}
		} else if {~ $#* <={%range 3-10} && ~ $* <={%prefixes judge}} {
			* = $*(2 ...)
			escape {|fn-break| while true {
				printf '1-%d,r,s,t,q? ' $#*
				let (i = <=%read-char) {
					echo
					~ $i q && break
					~ $i t && equalizer toggle >/dev/null
					~ $i s && {
						equalizer curve
						equalizer status
					}
					~ $i r && {let (r; n; i) {
						r = <=$&random
						n = $#*
						i = `($r%$n+1)
						equalizer load $*($i)
						equalizer enable >/dev/null
					}}
					if {~ $i <={%range 1-$#*}} {
						equalizer load $*($i)
						equalizer enable >/dev/null
					}
				}
			}}
		} else if {~ $* <={%prefixes info}} {
			echo \
'The equalizer is configured via an "active" file. The `load`
subcommand moves a preset into the "active" file; the `enable`
subcommand (re)starts the equalizer to load the "active" file.'
		} else if {~ $* <={%prefixes adjust}} {
			let (bands; b; h; gains; tf; name; pf) {
			let (fn-u = {|v| let (g) {
				g = $gains(`($b+1))
				switch $v (
				+ {g = `{echo $g|sed 's/-//'}}
				- {g = `{echo $g|sed 's/^.\../-&/'}}
				{if {~ $h 1} {
					g = `{echo $g|sed 's/\(-\?\).\(\..\)/' \
							^'\1'^$v^'\2/'}
				} else {
					g = `{echo $g|sed 's/\(-\?.\.\)./' \
							^'\1'^$v^'/'}
				}}
				)
				gains = $gains(1 ... $b) $g $gains(`($b+2) ...)
				printf $v
			}}; fn-flat = {
				g = $gains(`($b+1))
				gains = $gains(1 ... $b) 0.0 $gains(`($b+2) ...)
				tput cup $b 0
				printf +0.0
				tput cup $b $h
			}; fn-rep = {|*|
				tput civis
				tput cup `($bands+1) 0
				tput ed
				printf %s%s%s <=.%ah $^* <=.%ahe
				tput cup $b $h
				tput cnorm
			}; fn-load = {
				clear
				equalizer curve
				bands = `{tail -n+10 $cf|head -1}
				gains = gains `{tail -n+11 $cf|head -$bands}
				b = 1
				h = 1
				tput cup $b $h
			}; fn-update = {
				tf = `mktemp
				head -10 $cf > $tf
				for g $gains(2 ...) {echo $g >> $tf}
				tail -n+`($bands+10+1) $cf >> $tf
				mv $tf $cf
				equalizer enable >/dev/null
			}; fn-save = {
				pf = $pd/^`` \n {tail -n+5 $cf \
							|head -1}^'.preset'
				ed -s $cf <<EOF
6,9d
w $pf
q
EOF
			}; fn-revert = {
				pf = $pd/^`` \n {tail -n+5 $cf \
							|head -1}^'.preset'
				ed -s $pf <<EOF
5a
0
0
-10
10
.
w $cf
q
EOF
				equalizer enable >/dev/null
				clear
				equalizer curve
				gains = gains `{tail -n+11 $cf|head -$bands}
			}; fn-new = {
				tput cup `($bands+1) 0
				tput ed
				printf 'new preset name: '
				name = <=read
				pf = $pd/$name^'.preset'
				if {access -f $pf} {
					result $name^' exists; not changed'
				} else {
					ed -s $cf <<EOF
5c
$name
.
6,9d
w $pf
q
EOF
					result active saved as $pf
				}
			}; fn-getc = {
				%without-echo {result <=%read-char}
			}; fn-redraw = {
				clear
				equalizer curve
			}) {
			load
			rep '? for help'
			escape {|fn-break| while true {
				switch <=getc (
				h {h = 1; rep}
				j {{$b :lt $bands && b = `($b+1)}; rep}
				k {{$b :gt 1 && b = `($b-1)}; rep}
				l {h = 3; rep}
				0 {u 0; rep}
				1 {u 1; rep}
				2 {u 2; rep}
				3 {u 3; rep}
				4 {u 4; rep}
				5 {u 5; rep}
				6 {u 6; rep}
				7 {u 7; rep}
				8 {u 8; rep}
				9 {u 9; rep}
				+ {tput cup $b 0; u +; rep}
				\= {tput cup $b 0; u +; rep}
				- {tput cup $b 0; u -; rep}
				f {flat}
				q {tput cup `($bands+1) 0; tput ed; break}
				s {save; rep active saved as $pf}
				n {rep <=new}
				r {revert; rep reverted to $pf}
				u {update; rep updated active}
				t {rep `{equalizer toggle}}
				v {redraw}
				z {load; rep cancelled edits}
				\? {rep \
'hjkl: move; 0123456789+-f: set; u: update active; z: cancel edits
r: revert from preset; s: save to preset; n: save as new preset
t: toggle active; i: info; v: redraw; q: quit'
				}
				i {
					# limit this text to six lines
					rep \
'The equalizer is configured via an "active" file. The "active" file
is loaded into the equalizer when the equalizer (re)starts.
 - The `u` (update) binding saves edits to "active" and loads "active".
 - The `z` (cancel) binding discards unsaved edits.
 - The `r` (revert) binding loads the current preset into "active"
   and loads "active".
 - The `s` (save) binding saves "active" to the current preset.'
				}
				{rep '? for help'}
				)
				printf `{tput cup $b $h}
			}}}}
		} else {
			.usage equalizer
		}
	}
}

fn gallery {|*|
	.d 'Random slideshow'
	.a 'PATH [DELAY]'
	.c 'media'
	%only-X
	if {~ $#* 0} {
		.usage gallery
	} else {let (dir = $(1); time = $(2)) {
		~ $time () && time = 5
		find -L $dir -type f|shuf|sxiv -qifb -sf -S$time >[2]/dev/null
	}}
}

fn grayview {|*|
	.d 'View image in grayscale'
	.a 'FILE ...'
	.c 'media'
	%only-X
	if {~ $#* 0} {
		.usage grayview
	} else {
		let (tf; _; ext) {
			for f $* {
				unwind-protect {
					(_ ext) = <={~~ $f *.*}
					tf = `mktemp^.$ext
					convert $f -type grayscale $tf
					sxiv -qb $tf
				} {
					rm -f $tf
				}
			}
		}
	}
}

fn image {|*|
	.d 'Display image'
	.a 'FILE ...'
	.c 'media'
	%only-X
	if {~ $#* 0} {
		.usage image
	} else {
		sxiv -qb $* &
	}
}

fn m {|*|
	.d 'Display metadata for audio track'
	.a 'TRACK_FILE'
	.a '(none)  # current track'
	.c 'media'
	%with-terminal m {let (track = $^*) {
		~ $track '' && track = <=%track-file
		~ $track () && throw error m 'no current/given track'
		mediainfo -f $track|%wt-pager
	}}
}

fn media-duration {|*|
	.d 'Report playback duration of media file'
	.a 'FILE...'
	.a '-t FILE...  # total'
	.c 'media'
	if {~ $*(1) -t} {
		let (th = 0; tm = 0; ts = 0; tt = 0) {
			%with-read-lines <{media-duration $*(2 ...)} {|line|
				let ((h m s t _) = <={~~ $line *:*:*.*\ *}) {
					th = `($th+$h)
					tm = `($tm+$m)
					ts = `($ts+$s)
					tt = `($tt+$s)
				}
			}
			ts = `($ts+$tt/1000)
			tt = `($tt%1000)
			tm = `($tm+$ts/60)
			ts = `($ts%60)
			th = `($th+$tm/60)
			tm = `($tm%60)
			printf %02d:%02d:%02d.%03d\n $th $tm $ts $tt
		}
	} else {
		mediainfo --Output=General\;%Duration/String3%\ %CompleteName%\\n $*
	}
}

fn midi {|*|
	.d 'Play MIDI files'
	.a 'FILE ...'
	.c 'media'
	if {~ $#* 0} {
		.usage midi
	} else {let (s; p) { unwind-protect {
			fluidsynth -a pulseaudio -m alsa_seq -s -i -l \
				/usr/share/soundfonts/FluidR3_*.sf2 \
				>/dev/null >[2=1] &
			s = $apid
			sleep 1
			p = `{aplaymidi -l|grep FLUID|cut -d' ' -f1}
			for f $* {aplaymidi -p $p $f}
		} {
			kill $s
		}
	}}
}

fn mpv {|*|
	.d 'Movie player'
	.a '[mpv_OPTIONS] FILE ...'
	.c 'media'
	.f 'wrap'
	%only-X
	result %with-terminal
	if {~ $#* 0} {
		.usage mpv
	} else {
		/usr/bin/mpv --volume=50 --no-stop-screensaver $*
	}
}

fn mpvl {|*|
	.d 'Movie player w/ volume leveler'
	.a '[mpv_OPTIONS] FILE ...'
	.c 'media'
	%only-X
	result %with-terminal
	if {~ $#* 0} {
		.usage mpvl
	} else {let (afconf = 'lavfi=[highpass=f=100,dynaudnorm=f=100:r=0.7' \
			^':c=1:m=20.0:b=1]'; \
		msg3conf = '${filename/no-ext}\n\n  ${time-pos}' \
                        ^' (${percent-pos}%) / ${duration}' \
                        ^'  [${playlist-pos-1} / ${playlist-count}]' \
                        ^'  volume ${volume}% ${width}x${height}') {
		mpv --af=$afconf -osd-msg3=$msg3conf --osd-font-size=31 $*
	}}
}

fn noise {|*|
	.d 'Audio noise generator'
	.a '[white|pink|brown [LEVEL_DB]]'
	.c 'media'
	let (pc = $*(1); pl = $*(2); color = pink; pad = -6; level = -20; \
		volume) {
		~ $pc brown && {color = brown; pad = 0}
		~ $pc pink && {color = pink; pad = -6}
		~ $pc white && {color = white; pad = -12}
		if {~ $pl -* || ~ $pl 0} {level = $pl} else {level = -20}
		volume = `($level + $pad)
		%without-echo %with-quit {
			play </dev/zero -q -t s32 -r 22050 -c 2 - \
				synth $color^noise tremolo 0.05 30 \
				vol $volume dB
		}
	}
}

fn p {
	.d 'Pulse Audio mixer'
	.c 'media'
	%with-terminal p %preserving-title {
		catch {|e|
			~ $e 'disconnected' && {
				echo 'Attempting to reconnect'
				pkill pulseaudio
				pulseaudio --start
				throw retry
			}
		} {
			/usr/local/bin/pamixer --color 1 \
						|| throw error p 'disconnected'
		}
	}
}

fn pdfposter {|*|
	.d 'Split a PDF poster to multiple letter-size sheets with cut marks'
	.a '[-s SCALE_FACTOR] PDF_INFILE PDF_OUTFILE'
	.c 'media'
	.f 'wrap'
	if {!~ $#* 2 4} {.usage pdfposter}
	let (scale = 1.0; in; out) {
		~ $*(1) -s && {scale = $*(2); * = $*(3 ...)}
		(in out) = $(1 2)
		access -f -- $in || throw error 'file?'
		# Ref: http://leolca.blogspot.com/2010/06/pdfposter.html
		%with-suffixed-tempfile tf .pdf {
			%with-throbber 'Processing ... ' {
				/usr/bin/pdfposter -m190x254mm -s $scale $in $tf
				pdflatex <<EOF
\documentclass{article}
% Support for PDF inclusion
\usepackage[final]{pdfpages}
% Support for PDF scaling
\usepackage{graphicx}
\usepackage[dvips=false,pdftex=false,vtex=false]{geometry}
\geometry{
   paperwidth=190mm,
   paperheight=254mm,
   margin=2.5mm,
   top=2.5mm,
   bottom=2.5mm,
   left=2.5mm,
   right=2.5mm,
   nohead
}
\usepackage[cam,letter,center,dvips]{crop}
\begin{document}
% Globals: include all pages, don't auto scale
\includepdf[pages=-,pagecommand={\thispagestyle{plain}}]{$tf}
\end{document}
EOF
			}
		}
		mv texput.pdf $out
		rm -f texput.*
		echo 'Output on' $out
	}
}

fn sonic-visualiser {|*|
	.d 'Audio file explorer'
	.a '[sonic-visualiser_OPTIONS]'
	.c 'media'
	.f 'wrap'
	result %with-terminal
	/usr/bin/sonic-visualiser $* >[2]/dev/null
}

fn sm {|*|
	.d 'Search music'
	.a 'MATCH'
	.c 'media'
	%with-terminal sm {
		grep -i $^* ~/.config/cmus/lib.pl \
			| sed 's|^'^$HOME^'/Music/||' \
			| sed 's/\.\(mp3\|wav\|ogg\|flac\)$//' \
			| sed 's!/! - !g' | sed 's! - [0-9]\{2\} ! - !' \
			| %wt-pager
	}
}

fn sp {|*|
	.d 'Search and play track'
	.a 'MATCH'
	.a '+  # next MATCH'
	.a '-  # previous MATCH'
	.c 'media'
	result %with-terminal
	cmus-command view sorted
	let (sr; wrap; tag = Search/play) {
		switch $^* (
		+ {sr = `{cmus-command search-next}}
		- {sr = `{cmus-command search-prev}}
		'' {throw error sp 'match?'}
		{cmus-command /^$^*}
		)
		wrap = <={~ $^sr 'search hit BOTTOM,'* 'search hit TOP,'*}
		if {~ $sr () || result $wrap} {
			result $wrap && {
				report $tag $sr
				test -t 0 || sleep 1
			}
			cmus-command win-activate
			report $tag `t
		} else {report $tag $sr}
	}
}

fn t {|*|
	.d 'Display currently-playing track'
	.c 'media'
	let (info; s; sc; p; pm; ps; d; dm; ds) {
		info = <={%flatten '  -  ' `` \n {cmus-remote -C status \
				|grep '^tag \(artist\|album\|title\|date\)' \
				|cut -d' ' -f3-}}
		s = `{cmus-remote -C status|grep '^status'|cut -d' ' -f2}
		switch $s (
		playing {sc = \>}
		paused {sc = \|}
		)
		info = $info ' ['$sc^']'
		p = `{cmus-remote -C status|grep '^position'|cut -d' ' -f2}
		pm = <={%intpart `($p/60)}
		ps = `($p%60)
		d = `{cmus-remote -C status|grep '^duration'|cut -d' ' -f2}
		dm = <={%intpart `($d/60)}
		ds = `($d%60)
		info = $info `{printf %u:%02u/%u:%02u $pm $ps $dm $ds}
		~ $info '' && info = 'No track'
		echo $info
	}
}

fn track {
	.d 'Show currently-playing track in a window'
	.c 'media'
	result %with-terminal
	stq -g 80x2 -T track -e xs -c '%without-cursor watch -n1 -t xs -c t' &
}

fn vidshuffle {|*|
	.d 'Shuffle videos under directory'
	.a 'DIRECTORY [FILTER_GLOB]'
	.c 'media'
	if {~ $#* 0} {
		.usage vidshuffle
	} else {let (dir = $(1); filt = $(2); scale) {
		~ $filt () && filt = '*'
		#~ `tty /dev/tty* && scale = --vf scale=`{fbset \
		#	|grep -o '[0-9]\+[0-9]\+'|tr x :}
		mpvl --really-quiet $scale --fs --image-display-duration=7 \
			--playlist <{find -L $dir -type f -iname $filt|shuf \
			|awk '/^[^/]/ {print "'`pwd'/"$0} /^\// {print}'}
	}}
}

fn vol {|*|
	.d 'Show/set volume of default PulseAudio output'
	.a '[%VOLUME]'
	.c 'media'
	if {~ $#* 1} {
		pamixer --set-volume $*
	} else {
		if {~ `{pamixer --get-mute} 1} {
			report Volume muted} \
		else {
			report Volume `{pamixer --get-volume|cut -d\  -f1}^%
		}
	}
}
