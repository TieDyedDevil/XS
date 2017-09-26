# Prompt control for xs

let (pi_p = $prompt_init(1); pi_a = $prompt_init(2); pi_s = $prompt_init(3)) {
	if {!~ <={%aref pr $pi_p} ()} {_op = <={%aref pr $pi_p} ''} \
	else {_op = \> \| xs}
	if {!~ $pi_a ()} {_oa = `{.tattr $pi_a}} \
	else {_oa = `{.tattr bold}}
	if {!~ $pi_s ()} {_ob = $pi_s} \
	else {_ob = underline}
}
local (_pr@$pid; _n@$pid; _s@$pid; _p1@$pid; _p2@$pid; _pt@$pid; _pa@$pid) {
	fn prompt {|x|
		.d 'Alter prompt'
		.a '-o P1 P2 PT # redefine initial prompt'
		.a 'P1 P2 PT'
		.a 'P1 P2'
		.a 'PT'
		.a '-a bold|normal|dim|italic'
		.a '-a red|green|blue'
		.a '-a yellow|magenta|cyan'
		.a '-s underline|highlight|normal'
		.a '-l  # list defined prompts'
		.a '-n NUM'
		.a '(none)  # restore initial prompt'
		.c 'prompt'
		.r 'name title rp sc sd se'
		if {~ $x(1) -o} {
			if {~ $#x 4} {_op = $x(2 ...)} \
			else {throw error prompt 'P1 P2 PT'}
		}
		if {~ $x(1) -l} {
			let (n = 1) {
				while {!~ <={%aref pr $n} ()} {
					printf '%d %s %s'\n $n <={%aref pr $n}
					n = `($n + 1)
				} | pr -8 -t
			}
		}
		if {~ $x(1) -n} {
			let (n = $x(2)) {
				!~ <={%aref pr $n} () && prompt <={%aref pr $n}
			}
		}
		if {~ $x(1) -s} {
			if {~ $x(2) underline} {
				_pb@$pid = underline
			} else if {~ $x(2) highlight} {
				_pb@$pid = highlight
			} else if {~ $x(2) normal} {
				_pb@$pid = normal
			} else {
				throw error prompt 'underline|highlight|normal'
			}
		}
		if {~ $x(1) -a} {
			if {{~ $#x 2} && {~ $x(2) (bold normal dim italic
					red green blue yellow magenta cyan)}} {
				let (svpa = $(_pa@$pid)) {
					_pa@$pid = `{.tattr $x(2)}
					~ $#(_pa@$pid) 0 && {_pa@$pid = $svpa}
				}
			} else {throw error prompt 'bold|normal|dim|italic' \
				^'|red|green|blue|yellow|magenta|cyan'}
		} else if {~ $#x 2 3 && !~ $x(1) -*} {
			_p1@$pid = $x(1); _p2@$pid = $x(2)
		}
		if {~ $#x 3 1 && !~ $x(1) -*} {_pt@$pid = $x($#x)}
		if {~ $x ()} {
			_p1@$pid = $_op(1); _p2@$pid = $_op(2)
			_pt@$pid = $_op(3)
			_pa@$pid = $_oa
			_pb@$pid = $_ob
		}
		if {~ $(_pt@$pid) () ''} {
			_pr@$pid = ($(_p1@$pid)^' ' $(_p2@$pid)^' ')
		} else {
			_pr@$pid = ('•'^$(_pt@$pid)^'•'^$(_p1@$pid)^' '
				    '•'^$(_pt@$pid)^'•'^$(_p2@$pid)^' ')
		}
	}
	fn %prompt {
		.palette; .an; .ed; .cn
		~ $(_pr@$pid) () && {
			_pa@$pid = $_oa; prompt; _n@$pid = 0; _s@$pid = -1
			_pb@$pid = $_ob
		}
		let ((p1 p2) = $(_pr@$pid); sn) {
			if {~ $(_n@$pid) -1} {
				prompt = $p1 $p2
			} else {
				let (seq = $(_n@$pid)) {
					_n@$pid = `($seq+1)
					sn = `` '' {printf %3d $(_n@$pid)}
					if {~ $(_pb@$pid) underline} {
						sn = `.au^$sn^`.aue
					}
					if {~ $(_pb@$pid) highlight} {
						sn = `.ah^$sn^`.ahe
					}
				}
				prompt = $sn$p1 $sn$p2
			}
			prompt = ($(_pa@$pid)^$prompt(1)^`.an
				  $(_pa@$pid)^$prompt(2)^`.an)
		}
	}
	fn sc {
		.d 'Prompt seqnum continue'
		.c 'prompt'
		.r 'prompt rp sd se'
		~ $(_s@$pid) -1 || _n@$pid = $(_s@$pid)
	}
	fn sd {
		.d 'Prompt seqnum disable'
		.c 'prompt'
		.r 'prompt rp sc se'
		_s@$pid = $(_n@$pid); _n@$pid = -1
	}
	fn se {
		.d 'Prompt seqnum enable'
		.c 'prompt'
		.r 'prompt rp sc sd'
		_n@$pid = 0; _s@$pid = -1
	}
}
fn rp {
	.d 'Random prompt'
	.c 'prompt'
	.r 'prompt sc sd se'
	let (np = 1; na = 10; att = (normal bold dim italic red green blue
					magenta yellow cyan); r; i; a) {
		while {!~ <={%aref pr $np} ()} {np = `($np + 1)}
		np = `($np - 1)
		r = <=$&random
		i = `($r % $np + 1)
		prompt <={%aref pr $i} $(_pt@$pid)
		a = ()
		while {~ $a ()} {
			i = `($r / 100 % $na + 1)
			a = `{.tattr $att($i)}
			r = <=$&random
		}
		prompt -a $att($i)
	}
}
