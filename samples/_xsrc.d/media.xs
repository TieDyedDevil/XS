fn b {
	.d 'Stop playing track'
	.c 'media'
	.r 'm mpc n played s'
	mpc -q pause
	m
}
fn gallery {|*|
	.d 'Random slideshow'
	.a 'PATH [DELAY]'
	.c 'media'
	if {~ $#* 0} {
		.usage gallery
	} else {let (dir = $(1); time = $(2)) {
		~ $time () && time = 5
		if {~ $TERM linux} {
			fbi -l <{find -L $dir -type f|shuf} \
				-t $time --autodown \
				--noverbose --blend 500 >[2]/dev/null
		} else if {~ $DISPLAY () && ~ `consoletype pty} {
			mpv --image-display-duration $time --really-quiet \
				--playlist <{find -L $dir -type f \
				|grep -e .jpg\$ -e .png\$|shuf|awk \
				'/^[^/]/ {print "'`pwd'/"$0} /^\// {print}'} \
				>[2]/dev/null

		} else {
			find -L $dir -type f|shuf|sxiv -qifb -sf -S$time \
				>[2]/dev/null
		}
	}}
}
fn image {|*|
	.d 'Display image'
	.a 'FILE ...'
	.c 'media'
	if {~ $#* 0} {
		.usage image
	} else if {~ $TERM linux} {
		fbi --noverbose $*
	} else if {~ $DISPLAY () && ~ `consoletype pty} {
		mpv --image-display-duration inf --really-quiet $*
	} else {
		sxiv -qfb $*
	}
}
fn m {|*|
	.d 'Show currently playing track'
	.a '[-w]'
	.c 'media'
	.r 'b mpc n played s'
	if {~ $* -w} {
		%with-quit {
			watch -x -p -t -n1 -c xs -c 'm >[2]/dev/null|head -1'}}
	%with-tempfile mi {
		mpc > $mi
		if {!grep -o '^ERROR: .*$' $mi} {
			~ `{cat $mi|wc -l} 3 && \
			printf '%s|  '^`.as^'%s'^`.an^'  |%s %s'\n \
				`` \n {cat $mi|head -1|cut -d\| -f1} \
				`` \n {cat $mi|head -1|cut -d\| -f2|cut -c3-} \
				`` \n {cat $mi|tail -n+2|head -1|xargs echo \
					|cut -d' ' -f3-} \
				`{grep -Eo '\[(playing|paused)\]' $mi}
			printf %s%s%s\n <=.%ad <={%flatten '; ' \
				`{cat $mi|tail -1|sed 's/: /:/g'}} <=.%an
		}
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
fn mpc {|*|
	.d 'Music player'
	.c 'media'
	.r 'b m n played s'
	/usr/bin/mpc -f '%artist% - %album% - %track%#|  %title%' $*
}
fn mpv {|*|
	.d 'Movie player'
	.a '[mpv_OPTIONS] FILE ...'
	.c 'media'
	if {~ $#* 0} {
		.usage mpv
	} else {let (embed; video_driver) {
		if {~ $DISPLAY ()} {
			video_driver = drm
		} else {
			embed = --wid=$XEMBED
			video_driver = opengl-hq
		}
		/usr/bin/mpv --profile $video_driver $embed \
			--volume=50 --no-stop-screensaver $*
	}}
}
fn mpvl {|*|
	.d 'Movie player w/ volume leveler'
	.a '[mpv_OPTIONS] FILE ...'
	.c 'media'
	if {~ $#* 0} {
		.usage mpvl
	} else {let (afconf = 'lavfi=[highpass=f=100,dynaudnorm=f=100:r=0.7:c=1' \
		^':m=20.0:b=1]') {
		mpv --af=$afconf $*
	}}
}
fn n {
	.d 'Play next track'
	.c 'media'
	.r 'b mpc n played s'
	if {~ `mpc \[playing\]} {mpc -q next} else {mpc -q play}
	m
}
fn played {
	.d 'List recently-played tracks'
	.c 'media'
	.r 'b m mpc n s'
	cat ~/.mpd/mpd.log|cut -c24-|grep '^played'|tail -n 15|tac|nl|tac
}
fn s {|*|
	.d 'Seek within current track'
	.a '+[MM:]SS  # forward relative'
	.a '-[MM:]SS  # backward relative'
	.a '[MM:]SS  # absolute time'
	.a 'N%  # absolute percent'
	.c 'media'
	.r 'b m mpc n played'
	if {~ $#* 0} {
		.usage s
	} else {
		mpc seek $*
	}
}
fn vidshuffle {|*|
	.d 'Shuffle videos under directory'
	.a 'DIRECTORY'
	.c 'media'
	if {~ $#* 0} {
		.usage vidshuffle
	} else {let (dir = $(1); filt = $(2); scale) {
		~ $filt () && filt = '*'
		~ `consoletype vt && scale = --vf scale=`{fbset \
			|grep -o '[0-9]\+[0-9]\+'|tr x :}
		mpvl --really-quiet $scale --fs --playlist <{find -L $dir \
			-type f -iname $filt|shuf \
			|awk '/^[^/]/ {print "'`pwd'/"$0} /^\// {print}'}
	}}
}
fn vol {
	.d 'Show volume of default PulseAudio output'
	.c 'media'
	if {~ `{pamixer --get-mute} 1} {printf Volume:\ muted\n} \
	else {printf Volume:\ %d%%\n `{pamixer --get-volume|cut -d\  -f1}}
}
