## Framebuffer resize
fn vtfhd {
	.d 'Set framebuffer size 1920x1080 (16:9)'
	.c 'framebuffer'
	.r 'vtqfhd vtqhd vtuwqhd vtuw-uxga vtwxga vtfbfit'
	.fbset 1920 1080
}
fn vtqfhd {
	.d 'Set framebuffer size 3840x2160 (16:9)'
	.c 'framebuffer'
	.r 'vtfhd vtqhd vtuwqhd vtuw-uxga vtwxga vtfbfit'
	.fbset 3840 2160
}
fn vtqhd {
	.d 'Set framebuffer size 2560x1440 (16:9)'
	.c 'framebuffer'
	.r 'vtfhd vtqfhd vtuwqhd vtuw-uxga vtwxga vtfbfit'
	.fbset 2560 1440
}
fn vtuwqhd {
	.d 'Set framebuffer size 3440x1440 (21:9)'
	.c 'framebuffer'
	.r 'vtfhd vtqfhd vtqhd vtuw-uxga vtwxga vtfbfit'
	.fbset 3440 1440
}
fn vtuw-uxga {
	.d 'Set framebuffer size 2560x1080 (21:9)'
	.c 'framebuffer'
	.r 'vtfhd vtqfhd vtqhd vtuwqhd vtwxga vtfbfit'
	.fbset 2560 1080
}
fn vtwxga {
	.d 'Set framebuffer size 1366x768 (16:9)'
	.c 'framebuffer'
	.r 'vtfhd vtqfhd vtqhd vtuwqhd vtuw-uxga vtfbfit'
	.fbset 1366 768
}
fn vtfbfit {
	.d 'Fit framebuffer to largest display'
	.c 'framebuffer'
	.r 'vtfhd vtqfhd vtqhd vtuwqhd vtuw-uxga vtwxga'
	if {~ $TERM linux} {
		let (best; hv) {
			best = `{cat /sys/class/drm/*/modes \
				|grep -Eo '[[:digit:]]+x[[:digit:]]+' \
				|sort -gr|uniq|head -1}
			echo Using $best
			hv = `` x {echo -n $best}
			.fbset $hv
		}
	} else {echo 'not a vt'}
}
