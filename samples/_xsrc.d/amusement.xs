fn aquarium {|*|
	.d 'Aquarium in root window'
	.a '[off|xfishtank_OPTIONS]'
	.c 'amusement'
	if {~ $* off} {
		pkill xfishtank
	} else {
		pgrep -c xfishtank >/dev/null || {xfishtank -b 43 -f 23 \
							-i 0.05 -r 0.1 $* &}
	}
}
fn cookie {
	.d 'Fortune'
	.c 'amusement'
	let (subjects = art computers cookie definitions goedel \
			humorists literature people pets platitudes \
			politics science wisdom) {
		fortune -n 200 -s $subjects
	}
}
fn wisepony {
	.d 'Wise pony'
	.c 'amusement'
	cookie|ponysay|less -eRFX
}
fn worms {|*|
	.d 'Display worms'
	.a '[worms_OPTIONS]'
	.c 'amusement'
	%with-terminal %with-quit {
		/usr/bin/worms -n 7 -d 50 $*
	}
}
