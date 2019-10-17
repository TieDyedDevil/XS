# Show indicators for no-newline and false return code of prior command.
fn %before-interactive-prompt {|rc|
	let ((r c) = <={catch {result 1 1} {result <=%get-cursor-position}}; \
	lights = ''; ga; gr; gn; prompt_lights) {
		if {~ `tty /dev/tty*} {
			ga = <=.%an^<={.%af 3}^<=.%ar
			gr = '0 '
			gn = 'n '
		} else {
			ga = <=.%an^<={.%af 3}^<=.%ab^<=.%ar
			gr = '🄌 '
			gn = '🄽 '
		}
		result $rc || lights = $lights^$gr
		~ $c 1 || { printf \n; lights = $lights^$gn; }
		prompt_lights = `` \n {printf '%s%s%s' $ga $lights <=.%an}
		prompt = `` \n {echo $prompt(1) \
			|sed 's/^\(.*\)\(.\[[0-9;]*.\?m.\+ [^ ]\+\)$/\1' \
				^$prompt_lights^'\2/'} \
			`` \n {echo $prompt(2) \
			|sed 's/^\(.*\)\(.\[[0-9;]*.\?m.\+ [^ ]\+\)$/\1' \
				^<=.%an^'\2/'} \
	}
}

# Define prompt defaults for console and pty, as:
# index of prompt, prompt attribute, sequence attribute
%aset pr cinit 6 green highlight # vt  default
%aset pr pinit 6 green highlight # pty default

# Define prompt pairs.
%aset pr 1 \u'252c' \u'251c'
%aset pr 2 \u'256a' \u'251c'
%aset pr 3 \u'250c' \u'251c'
%aset pr 4 \u'2510' \u'251c'
%aset pr 5 \u'00bb' \u'203a'
%aset pr 6 \u'0394' \u'00a6'
%aset pr 7 \u'041f' \u'045f'
%aset pr 8 \u'2500' \u'256c'
%aset pr 9 \u'03b1' \u'03b2'
%aset pr 10 \u'00b9' \u'00b2'
%aset pr 11 \u'03bb' \u'2026'
%aset pr 12 \u'03c8' \u'03c6'
%aset pr 13 \u'00a4' \u'2022'
%aset pr 14 \u'00b6' \u'00a7'
%aset pr 15 \u'03c1' \u'03c4'
%aset pr 16 \u'2020' \u'2021'
%aset pr 17 \u'0192' \u'2310'
%aset pr 18 \u'039b' \u'039e'

# Mark the largest index that'll work in the console.
%aset pr cmax 18

## The following won't render in the console.
%aset pr 19 \u'1f7b7' \u'1f7b1'
%aset pr 20 \u'2b95' \u'2b8a'
%aset pr 21 \u'1f664' \u'1f667'
%aset pr 22 \u'29ef' \u'29f3'
%aset pr 23 \u'29d0' \u'29ce'
%aset pr 24 \u'2058' \u'2059'
%aset pr 25 \u'2994' \u'2995'
%aset pr 26 \u'2032' \u'2033'
%aset pr 27 \u'269e' \u'269f'
%aset pr 28 \u'1f657' \u'1f652'
%aset pr 29 \u'16964' \u'16960'
%aset pr 30 \u'22cc' \u'22cb'
%aset pr 31 \u'1bfd' \u'1be5'
%aset pr 32 \u'29a6' \u'29a7'
%aset pr 33 \u'2251' \u'224e'
%aset pr 34 \u'2aa8' \u'2aa9'
%aset pr 35 \u'29e2' \u'2a33'
%aset pr 36 \u'fc3' \u'fc2'
%aset pr 37 \u'2a77' \u'2a66'
%aset pr 38 \u'12036' \u'12111'
%aset pr 39 \u'2135' \u'1d6c1'
%aset pr 40 \u'1212d' \u'1212c'
%aset pr 41 \u'1701' \u'1707'
%aset pr 42 \u'1f789' \u'1f7ae'
%aset pr 43 \u'29c9' \u'2a1d'
%aset pr 44 \u'12115' \u'12367'

# Mark the largest index that'll work in a pty.
%aset pr pmax 44
