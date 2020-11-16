# Show indicators for no-newline and false return code of prior command.
# Also show indicator for disabled history.
let (ga; _an; _attrs_defined = false; gr = ϴ; gn = ł; gh = И) {
fn %before-interactive-prompt {|rc|
	$_attrs_defined || {
		if {~ `tty /dev/tty*} {
			ga = <=.%an^<={.%af 3}^<=.%ar
		} else {
			ga = <=.%an^<={.%af 3}^<=.%ab^<=.%ar
		}
		_an = <=.%an
		_attrs_defined = true
	}
	let ((r c) = <={catch {result 1 1} {result <=%get-cursor-position}}; \
	lights = ''; prompt_lights; continue_lights; \
	fill = \u'2592'\u'2592'\u'2592') {
		if {!result $rc} {lights = $lights^$gr} \
						else {lights = $lights^' '}
		if {!~ $c 1} {printf \n; lights = $lights^$gn} \
						else {lights = $lights^' '}
		if {~ $history ()} {lights = $lights^$gh} \
						else {lights = $lights^' '}
		prompt_lights = `` \n {printf '%s%s%s' $ga $lights $_an}
		continue_lights = `` \n {printf '%s%s%s' $ga $fill $_an}
		prompt = $prompt_lights^$prompt(1) $continue_lights^$prompt(2)
	}
}
fn lights {
	.d 'Describe prompt lights'
	.c 'prompt'
	printf \t'%s%s  %s  nonzero result     ' $ga $gr $_an
	printf '%s %s %s  no newline     ' $ga $gn $_an
	printf '%s  %s%s  no history'\n $ga $gh $_an
}
}

# Define prompt defaults for console and pty, as:
# index of prompt, prompt attribute, sequence attribute
%aset pr cinit 2 cyan highlight # vt  default
%aset pr pinit 2 cyan highlight # pty default

let (i = 0) {
	fn .dpp {|*|
		i = `($i+1)
		%aset pr $i $*
		result $i
	}
}

# Define prompt pairs.
.dpp '>' '|'
.dpp ';' ' '
.dpp '+' '-'
.dpp '`' '~'
.dpp '&' '_'
.dpp '%' ''''
.dpp '#' '^'
.dpp '"' '*'
.dpp '$' '='
.dpp '@' '!'
.dpp \u'252c' \u'251c'
.dpp \u'250c' \u'251c'
.dpp \u'2510' \u'251c'
.dpp \u'0394' \u'00a6'
.dpp \u'041f' \u'045f'
.dpp \u'2500' \u'256c'
.dpp \u'03b1' \u'03b2'
.dpp \u'03bb' \u'2026'
.dpp \u'00a4' \u'2022'
.dpp \u'00b6' \u'00a7'
.dpp \u'03c1' \u'03c4'
.dpp \u'2020' \u'2021'
.dpp \u'0192' \u'2310'
%aset pr cmax <={ # Mark the largest index that'll work in the console.
.dpp \u'039b' \u'039e'
}


## The following won't render in the console.
.dpp \u'2b95' \u'2b8a'
.dpp \u'29d0' \u'29ce'
.dpp \u'2058' \u'2059'
.dpp \u'2994' \u'2995'
.dpp \u'2032' \u'2033'
.dpp \u'16964' \u'16960'
.dpp \u'fc3' \u'fc2'
.dpp \u'1f789' \u'1f7ae'
.dpp \u'26e4' \u'26e7'
.dpp \u'25bc' \u'25b2'
.dpp \u'25d9' \u'25cb'
.dpp \u'25a0' \u'25a1'
.dpp \u'25e7' \u'25e8'
.dpp \u'29c7' \u'29c8'
%aset pr pmax <={ # Mark the largest index that'll work in a pty.
.dpp \u'21aa' \u'2925'
}

fn .dpp
