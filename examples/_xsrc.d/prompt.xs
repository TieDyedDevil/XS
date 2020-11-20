# Prompt control for xs

# The following globals are used, where $pid is the PID of the current shell:
#   _pr@$pid	prompt pair, including trailing space
#   _n@$pid	sequence number (when enabled) or -1
#   _s@$pid	saved sequence number (when sequence disabled) or -1
#   _p1@$pid	prompt 1 character
#   _p2@$pid	prompt 2 character
#   _pt@$pid	prompt title
#   _pa@$pid	prompt foreground attribute
#   _pb@$pid	prompt background attribute
#   _op		original prompt pair
#   _oa		original prompt foreground attribute
#   _ob		original prompt background attribute
#   prompt	prompt pair with terminal controls

fn _prompt_init {
	let (prompt_init) {
		if {~ `tty /dev/tty*} {
			prompt_init = <={%aref pr cinit}
		} else {
			prompt_init = <={%aref pr pinit}
		}
		let (pi_p = $prompt_init(1); pi_a = $prompt_init(2); \
						pi_s = $prompt_init(3)) {
			if {!~ <={%aref pr $pi_p} ()} {
				_op = <={%aref pr $pi_p} ''
			} else {
				_op = \> \| xs
			}
			if {!~ $pi_a ()} {
				_oa = $pi_a
			} else {
				_oa = bold
			}
			if {!~ $pi_s ()} {
				_ob = $pi_s
			} else {
				_ob = underline
			}
		}
	}
}

_prompt_init

fn prompt {|x|
	.d 'Alter prompt'
	.a '-o PROMPT_1 PROMPT_2 PROMPT_TEXT # redefine initial prompt'
	.a 'PROMPT_1 PROMPT_2 PROMPT_TEXT'
	.a 'PROMPT_1 PROMPT_2'
	.a 'PROMPT_TEXT'
	.a '-a bold|normal|dim|italic'
	.a '-a red|green|blue'
	.a '-a yellow|magenta|cyan'
	.a '-s underline|highlight|normal'
	.a '-l  # list defined prompts'
	.a '-L  # list defined prompts with sample text'
	.a '-n NUM  # load defined prompt'
	.a '(none)  # restore initial prompt'
	.i 'The -a and -s options apply to the prompt sequence number.'
	.i 'If $PS1 and $PS2 are both set, use for PROMPT_1 and PROMPT_2.'
	.i 'The -a and -s options are ineffective when $PS1 and $PS2 are set.'
	.i 'PROMPT_TEXT overrides both $PS1 and $PS2.'
	.c 'prompt'
	.r 'name title rp psc psd psi pss sample'
	if {~ $x(1) -o} {
		if {~ $#x 4} {_op = $x(2 ...)} \
		else {throw error prompt 'P1 P2 PT'}
	}
	if {~ $x(1) -l} {
		let (pm; n = 1; pd) {
			if {~ `tty /dev/tty*} {
				pm = <={%aref pr cmax}
				pd = <={%aref pr cinit}
			} else {
				pm = <={%aref pr pmax}
				pd = <={%aref pr pinit}
			}
			while {$n :le $pm} {
				printf '%d %s %s'\n $n <={%aref pr $n}
				n = `($n + 1)
			} | pr -8 -t
			echo initial: $pd
		}
	}
	if {~ $x(1) -L} {
		let (pm) {
			if {~ `tty /dev/tty*} {
				pm = <={%aref pr cmax}
			} else {
				pm = <={%aref pr pmax}
			}
			for i <={%range 1-$pm} {
				prompt -n $i
				pss $i
				%prompt
				echo '#'^$prompt(1)^sample...
				echo '#'^$prompt(2)^sample...
				echo '#'^$prompt(2)^sample...
			}|less -RFX
		}
	}
	if {~ $x(1) -n} {
		let (pm; n = $x(2)) {
			if {~ `tty /dev/tty*} {
				pm = <={%aref pr cmax}
			} else {
				pm = <={%aref pr pmax}
			}
			if {{$n :le $pm} && {!~ <={%aref pr $n} ()}} {
				prompt <={%aref pr $n}
			} else {
				throw error prompt 'prompt number?'
			}
		}
	}
	if {~ $x(1) -s} {
		if {~ $x(2) underline} {
			~ $TERM linux && throw error prompt 'unsupported'
			_pb@$pid = underline
		} else if {~ $x(2) highlight} {
			if {~ $(_pa@$pid) dim} {
				throw error prompt 'not with dim'
			}
			~ $TERM linux && throw error prompt 'unsupported'
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
			~ $x(2) bold italic && ~ $TERM linux \
				&& throw error prompt 'unsupported'
			if {~ $x(2) dim && ~ $(_pb@$pid) highlight} {
				throw error prompt 'not with highlight'
			}
			let (svpa = $(_pa@$pid); ta) {
				_pa@$pid = $x(2)
				ta = `{.tattr $x(2)}
				{~ $ta ()} && {_pa@$pid = $svpa}
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
		if {!~ $PS1 () && !~ $PS2 ()} {
			_pr@$pid = $PS1 $PS2
			_pa@$pid = normal
			_pb@$pid = normal
		} else {
			_pr@$pid = ($(_p1@$pid)^' ' $(_p2@$pid)^' ')
		}
	} else {
		_pr@$pid = ('•'^$(_pt@$pid)^'•'^$(_p1@$pid)^' '
			    '•'^$(_pt@$pid)^'•'^$(_p2@$pid)^' ')
	}
	true
}

let (_an; _ed; _cn; _au; _aue; _ah; _ahe; _ad; _palette; _tattrs = <=%mkobj; \
_attr_names = bold normal dim italic red green yellow blue magenta cyan; \
_attrs_defined = false) {
fn %prompt {
	$_attrs_defined || {
		_an = <=.%an; _ed = <=.%ed; _cn = <=.%cn; _au = <=.%au;
		_aue = <=.%aue; _ah = <=.%ah; _ahe = <=.%ahe; _ad = <=.%ad;
		_palette = <={%argify `.palette}
		for an $_attr_names {
			%objset $_tattrs $an <={.%tattr $an}
		}
		_attrs_defined = true
	}
	printf %s $_palette^$_an^$_ed^$_cn
	~ $(_pr@$pid) () && {
		_prompt_init; rp
		_pa@$pid = $_oa; prompt; _n@$pid = 0; _s@$pid = -1
		_pb@$pid = $_ob
	}
	let ((p1 p2) = $(_pr@$pid); sn) {
		if {~ $(_n@$pid) -1} {
			prompt = $p1 $p2
		} else {
			let (seq = $(_n@$pid); \
			pattr = <={%objget $_tattrs $(_pa@$pid) ''}) {
				_n@$pid = `($seq+1)
				sn = `` '' {printf %3d $(_n@$pid)}
				if {~ $(_pb@$pid) underline} {
					sn = $_au^$sn^$_aue
				}
				if {~ $(_pb@$pid) highlight} {
					sn = $_ah^$sn^$_ahe
				}
				if {~ $(_pb@$pid) normal} {
					sn = $sn^$_an
				}
				prompt = ($pattr^$sn^$_an^$_ad^$p1^$_an
						$pattr^$sn^$_an^$_ad^$p2^$_an)
			}
		}
	}
}
}

fn psc {
	.d 'Prompt seqnum continue'
	.c 'prompt'
	.r 'prompt rp psd psi pss sample'
	~ $(_s@$pid) -1 || _n@$pid = $(_s@$pid)
	true
}

fn psd {
	.d 'Prompt seqnum disable'
	.c 'prompt'
	.r 'prompt rp psc psi pss sample'
	_s@$pid = $(_n@$pid); _n@$pid = -1
	true
}

fn psi {
	.d 'Prompt seqnum initialize'
	.c 'prompt'
	.r 'prompt rp psc psd pss sample'
	_n@$pid = 0; _s@$pid = -1
	true
}

fn pss {|num|
	.d 'Prompt seqnum set'
	.a 'SEQNUM'
	.c 'prompt'
	.r 'prompt rp psc psd psi sample'
	echo $num|grep -c '^[0-9]\{1,7\}$' >/dev/null \
		|| throw error pss 'seqnum?'
	~ $num 0 && num = 1
	_n@$pid = `($num-1); _s@$pid = -1
	true
}

fn rp {
	.d 'Random prompt'
	.c 'prompt'
	.r 'prompt psc psd psi sample'
	let (np = 1; na = 10; nb = 3; \
			att = (normal bold dim italic red green blue
				magenta yellow cyan); \
			bkg = (normal highlight underline); \
			r; i; j) {
		if {~ `tty /dev/tty*} {
			np = <={%aref pr cmax}
		} else {
			np = <={%aref pr pmax}
		}
		r = <=$&random
		i = `($r % $np + 1)
		prompt <={%aref pr $i} $(_pt@$pid)
		prompt -a normal
		prompt -s normal
		catch {
			throw retry
		} {
			catch {
				throw retry
			} {
				r = <=$&random
				i = `($r / 100 % $na + 1)
				prompt -a $att($i)
			}
			catch {
				throw retry
			} {
				r = <=$&random
				j = `($r / 100 % $nb + 1)
				prompt -s $bkg($j)
			}
			~ $i 1 && ~ $j 1 && throw error prompt 'normal normal'
			~ $i 9 && ~ $j 1 && throw error prompt 'yellow normal'
			true
		}
	}
}

fn sample {|*|
	.d 'Show prompt sample.'
	.a '[all]'
	.c 'prompt'
	.r 'prompt psc psd psi rp'
	if {~ $* all} {
		{
		.as
		for i <={%range 1-^<={%aref pr pmax}} {printf %d\  `($i/10)}
		.an
		printf \n
		.as
		for i <={%range 1-^<={%aref pr pmax}} {printf %d\  `($i%10)}
		.an
		printf \n
		for r (1 2 2 1) {
			let (p;c) {
				for i <={%range 1-^<={%aref pr pmax}} {
					p = <={%aref pr $i}
					c = $p($r)
					printf %s\  $c
				}
			}
			printf \n
		}
		} | tr -d \017 | less -RFS
	} else {
		printf +%ssample\ ...\n $prompt(2)
		printf +%ssample\ ...\n $prompt(2)
	}
}

fn .init_random_prompt {
	# This is meant to be invoked *only* from ~/.xsin .
	%prompt; rp; _n@$pid = 0
	true
}
