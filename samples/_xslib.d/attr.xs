## Terminal presentation
fn .ab {
	# Set terminal attribute bold.
	tput bold
}
fn .%ab {
	# Return terminal attribute bold string.
	result <={%argify `.ab}
}
fn .abl {
	# Set terminal attribute blink.
	tput blink
}
fn .%abl {
	# Return terminal attribute bold blink.
	result <={%argify `.abl}
}
fn .ad {
	# Set terminal attribute dim.
	tput dim}
fn .%ad {
	# Return terminal attribute dim string.
	result <={%argify `.ad}
}
fn .ah {
	# Set terminal attribute background highlight begin.
	tput setab 8
}
fn .%ah {
	# Return terminal attribute background highlight begin.
	result <={%argify `.ah}
}
fn .ahe {
	# Set terminal attribute background highlight end.
	tput setab 0}
fn .%ahe {
	# Return terminal attribute background highlight end.
	result <={%argify `.ahe}
}
fn .ai {
	# Set terminal attribute italic.
	tput sitm
}
fn .%ai {
	# Return terminal attribute italic.
	result <={%argify `.ai}
}
fn .af {|n|
	# Set terminal attribute foreground.
	# 0=black; 1=red; 2=green; 3=yellow; 4=blue; 5=magenta; 6=cyan; 7=white
	tput setaf $n
}
fn .%af {|n|
	# Return terminal attribute foreground.
	# 0=black; 1=red; 2=green; 3=yellow; 4=blue; 5=magenta; 6=cyan; 7=white
	result <={%argify `{.af $n}}
}
fn .an {
	# Set terminal attribute normal.
	tput sgr0
}
fn .%an {
	# Return terminal attribute normal.
	result <={%argify `.an}
}
fn .as {
	# Set terminal attribute "special": dim if console; else italic.
	if {~ $TERM linux} .ad else .ai
}
fn .%as {
	# Return terminal attribute "special": dim if console; else italic.
	result <={%argify `.as}
}
fn .au {
	# Set terminal attribute underline begin.
	tput smul
}
fn .%au {
	# Return terminal attribute underline begin.
	result <={%argify `.au}
}
fn .aue {
	# Set terminal attribute underline end.
	tput rmul
}
fn .%aue {
	# Return terminal attribute underline end.
	result <={%argify `.aue}
}
fn .ci {
	# Set terminal attribute cursor invisible.
	tput civis
}
fn .%ci {
	# Return terminal attribute cursor invisible.
	result <={%argify `.ci}
}
fn .cn {
	# Set terminal attribute cursor visible.
	tput cnorm
}
fn .%cn {
	# Return terminal attribute cursor visible.
	result <={%argify `.cn}
}
fn .ed {
	# Put terminal erase to end of display.
	tput ed
}
fn .%ed {
	# Return terminal erase to end of display.
	result <={%argify `.ed}
}
fn .palette {
	# Adjust terminal color palette.
	if {~ $TERM linux} {
		printf %s \e]R
		printf %s \e]P0000000 # black = Black
		printf %s \e]P1cd0000 # red = Red3
		printf %s \e]P200cd00 # green = Green3
		printf %s \e]P3cdcd00 # yellow = Yellow3
		printf %s \e]P45f87d7 # blue = SteelBlue3
		printf %s \e]P5cd00cd # magenta = Magenta3
		printf %s \e]P600cdcd # cyan = Cyan3
		printf %s \e]P7e5e5e5 # white = Gray90
	} else {
		if {!~ $TERM st*} {
			tput initc 0 0 0 0 # black = Black
			tput initc 1 205 0 0 # red = Red3
			tput initc 2 0 205 0 # green = Green3
			tput initc 3 205 205 0 # yellow = Yellow3
			tput initc 4 95 135 215 # blue = SteelBlue3
			tput initc 5 205 0 205 # magenta = Magenta3
			tput initc 6 0 205 205 # cyan = Cyan3
			tput initc 7 229 229 229 # white = Gray90
			tput initc 8 77 77 77 # bright black - Gray30
			tput initc 12 99 184 255 # bright blue = SteelBlue1
		}
		if {~ $TERM yaft-256color} {
			tput initc 7 208 208 208 # normal white
			tput initc 12 99 184 255 # bright blue
			tput initc 15 255 255 255 # bright white
		}
	}
}
fn .tattr {|*|
	# Set terminal foreground attribute: bold, normal, dim, italic,
	# red, green, yellow, blue, magenta or cyan.
	let (cs) {
		switch $* (
		bold {cs = `.ab}
		normal {cs = `.an}
		dim {cs = `.ad}
		italic {cs = `.ai}
		red {cs = `{.af 1}}
		green {cs = `{.af 2}}
		yellow {cs = `{.af 3}}
		blue {cs = `{.af 4}}
		magenta {cs = `{.af 5}}
		cyan {cs = `{.af 6}}
		)
		~ $cs () || printf %s $cs
	}
}
fn .%tattr {|*|
	# Return terminal foreground attribute: bold, normal, dim, italic,
	# red, green, yellow, blue, magenta or cyan.
	result <={%argify `{.tattr $*}}
}
