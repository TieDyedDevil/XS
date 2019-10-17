fn defender {
	.d 'Williams Defender'
	.c 'game'
	result %with-terminal
	mame defender
}
fn gravitar {
	.d 'Atari Gravitar'
	.c 'game'
	result %with-terminal
	mame -contrast 1.8 gravitar
}
fn gyruss {
	.d 'Konami Gyruss'
	.c 'game'
	result %with-terminal
	mame gyruss
}
fn tacscan {
	.d 'Sega Tac/Scan'
	.c 'game'
	result %with-terminal
	mame -contrast 1.8 tacscan
}
fn tempest {
	.d 'Atari Tempest'
	.c 'game'
	result %with-terminal
	mame -video bgfx -contrast 1.5 tempest
}

fn mame {|*|
	.d 'MAME'
	.a '[mame_OPTIONS]'
	.c 'alias'
	unwind-protect {/usr/bin/mame -window $*} {rm -rf ~/history; hp}
}
