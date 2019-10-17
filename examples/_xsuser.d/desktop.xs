fn desktop {|*|
	.d 'Prepare desktop'
	.a '[-c]  # clear; leave status bar, pacer, gcal-remind and wallpaper'
	.a '[-b]  # bare; no wallpaper, pacer, gcal-remind or status bar'
	.c 'system'
	if {~ $* -c -b} {
		animate off
		aquarium off
		wallgen -c
		if {~ $* -b} {
			pacer off
			gcal-remind off
			bar off
		}
	} else {
		notify white\|Desktop Preparing: await "ready"...
		sleep 0.5
		.ensure-dmr-stubs &
		sleep 0.5
		pacer
		gcal-remind
		bar -m
		hp
		%refocus
		notify white3\|Desktop ready \(^<={%argify `pers}^\)
	}
}
