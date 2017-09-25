fn b {
	.d 'Stop playing track'
	.c 'media'
	.r 'm mpc n played'
	mpc -q pause
	m
}
fn gallery {|*|
	.d 'Random slideshow'
	.a 'PATH [DELAY]'
	.c 'media'
	let (dir = $(1); time = $(2)) {
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
			find -L $dir -type f|shuf|sxiv -qifb -sd -S$time \
				>[2]/dev/null
		}
	}
}
fn image {|*|
	.d 'Display image'
	.a 'FILE ...'
	.c 'media'
	if {~ $TERM linux} {
		fbi --noverbose $*
	} else if {~ $DISPLAY () && ~ `consoletype pty} {
		mpv --image-display-duration inf --really-quiet $*
	} else {
		sxiv -qfb $*
	}
}
fn m {|*|
	.d 'Show currently playing track'
	.c 'media'
	.r 'b mpc n played'
	%with-tempfile mi {
		mpc > $mi
		printf '%s|  '^`.as^'%s'^`.an^'  |%s %s'\n \
			`` \n {cat $mi|head -1|cut -d\| -f1} \
			`` \n {cat $mi|head -1|cut -d\| -f2|cut -c3-} \
			`` \n {cat $mi|tail -n+2|head -1|xargs echo \
				|cut -d' ' -f3-} \
			`{grep -Eo '\[(playing|paused)\]' $mi}
		printf %s%s%s\n `.ad <={%flatten '; ' \
			`{cat $mi|tail -1|sed 's/: /:/g'}} `.an
	}
}
fn mpc {|*|
	.d 'Music player'
	.c 'media'
	.r 'b m n played'
	/usr/bin/mpc -f '%artist% - %album% - %track%#|  %title%' $*
}
fn mpv {|*|
	.d 'Movie player'
	.a '[mpv_OPTIONS] FILE ...'
	.c 'media'
	let (embed; video_driver) {
		if {~ $DISPLAY ()} {
			video_driver = drm
		} else {
			embed = --wid=$XEMBED
			video_driver = opengl-hq
		}
		/usr/bin/mpv --profile $video_driver $embed \
			--no-stop-screensaver $*
	}
}
fn mpvl {|*|
	.d 'Movie player w/ volume leveler'
	.a '[mpv_OPTIONS] FILE ...'
	.c 'media'
	let (afconf = 'lavfi=[highpass=f=100,dynaudnorm=f=100:r=0.7:c=1' \
		^':m=20.0:b=1]') {
		mpv --af=$afconf $*
	}
}
fn n {
	.d 'Play next track'
	.c 'media'
	.r 'b mpc n played'
	if {~ `mpc \[playing\]} {mpc -q next} else {mpc -q play}
	m
}
fn played {
	.d 'List recently-played tracks'
	.c 'media'
	.r 'b m mpc n'
	cat ~/.mpd/mpd.log|cut -c24-|grep '^played'|tail -n 15|tac|nl|tac
}
fn vidshuffle {|*|
	.d 'Shuffle videos under directory'
	.a 'DIRECTORY'
	.c 'media'
	let (dir = $(1); filt = $(2); scale) {
		~ $filt () && filt = '*'
		~ `consoletype vt && scale = --vf scale=`{fbset \
			|grep -o '[0-9]\+[0-9]\+'|tr x :}
		mpvl --really-quiet $scale --fs --playlist <{find -L $dir \
			-type f -iname $filt|shuf \
			|awk '/^[^/]/ {print "'`pwd'/"$0} /^\// {print}'}
	}
}
