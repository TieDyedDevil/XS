fn gallery {|*|
	.d 'Random slideshow'
	.c 'media'
	.a 'PATH [DELAY]'
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
	.c 'media'
	.a 'FILE ...'
	if {~ $TERM linux} {
		fbi --noverbose $*
	} else if {~ $DISPLAY () && ~ `consoletype pty} {
		mpv --image-display-duration inf --really-quiet $*
	} else {
		sxiv -qfb $*
	}
}
fn m {
	.d 'Show currently playing track'
	.c 'media'
	let (mi = `mktemp) {
		mpc > $mi
		if {grep -q '\[playing\]' $mi} {
			printf '%s  |%s'\n `` \n {cat $mi|head -1} \
				`` \n {cat $mi|tail -n+2|head -1|xargs echo \
					|cut -d' ' -f3-}
		} else {echo 'Not playing'}
	}
}
fn mpc {|*|
	.d 'Music player'
	.c 'media'
	/usr/bin/mpc -f '%artist% - %album% - %track%#|  %title%' $*
}
fn mpv {|*|
	.d 'Movie player'
	.c 'media'
	.a '[mpv_OPTIONS] FILE ...'
	let (embed; video_driver) {
		if {~ $DISPLAY ()} {
			video_driver = drm
		} else {
			embed = --wid=$XEMBED
			video_driver = opengl-hq
		}
		/usr/bin/mpv --vo $video_driver $embed --no-stop-screensaver $*
	}
}
fn mpvl {|*|
	.d 'Movie player w/ volume leveler'
	.c 'media'
	.a '[mpv_OPTIONS] FILE ...'
	let (afconf = 'lavfi=[highpass=f=100,dynaudnorm=f=100:r=0.7:c=1' \
		^':m=20.0:b=1],volume=-9') {
		mpv --af=$afconf $*
	}
}
fn n {
	.d 'Play next track'
	.c 'media'
	if {~ `mpc \[playing\]} {mpc next} else {mpc play}
}
fn vidshuffle {|*|
	.d 'Shuffle videos under directory'
	.c 'media'
	.a 'DIRECTORY'
	let (dir = $(1); filt = $(2); scale) {
		~ $filt () && filt = '*'
		~ `consoletype vt && scale = --vf scale=`{fbset \
			|grep -o '[0-9]\+[0-9]\+'|tr x :}
		mpvl --really-quiet $scale --fs --playlist <{find -L $dir \
			-type f -iname $filt|shuf \
			|awk '/^[^/]/ {print "'`pwd'/"$0} /^\// {print}'}
	}
}
