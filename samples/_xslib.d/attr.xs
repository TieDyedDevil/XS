## Terminal presentation
fn .ab {tput bold}
fn .ad {tput dim}
fn .ah {tput setab 8}
fn .ahe {tput setab 0}
fn .ai {tput sitm}
fn .af {|n| tput setaf $n}
fn .an {tput sgr0}
fn .as {if {~ $TERM linux} .ad else .ai}
fn .au {tput smul}
fn .aue {tput rmul}
fn .ci {tput civis}
fn .cn {tput cnorm}
fn .ed {tput ed}
fn .palette {
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
		}
		if {~ $TERM yaft-256color} {
			tput initc 7 208 208 208 # normal white
			tput initc 12 99 185 255 # bright blue
			tput initc 15 255 255 255 # bright white
		}
	}
}
fn .tattr {|*|
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
