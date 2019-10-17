fn cookie {
	.d 'Fortune'
	.c 'amusement'
	let (subjects = art computers cookie definitions goedel \
			humorists literature people pets platitudes \
			politics science wisdom) {
		if {test -t 0} {fortune -n 200 -s $subjects} \
		else {notify Cookie `{fortune -n 100 -s $subjects}}
	}
}

fn rain {
	.d 'Rain'
	.c 'amusement'
	.f 'wrap'
	%with-terminal rain %with-quit /usr/bin/rain -d 100
}

fn wisepony {
	.d 'Wise pony'
	.c 'amusement'
	%with-terminal wisepony {cookie|ponysay|less -eRFX}
}

fn worms {|*|
	.d 'Display worms'
	.a '[worms_OPTIONS]'
	.c 'amusement'
	.f 'wrap'
	%with-terminal worms %with-quit {
		/usr/bin/worms -n 7 -d 50 $*
	}
}
