fn %advise {|name thunk|
	# Insert a thunk at the beginning of a function
	let (f = `` \n {var fn-$name}; c) {
		if {echo $f|grep -wqv $thunk} {
			c = `` \n {echo -- $f|sed 's/= ''\({\(|[^|]\+|\)\?' \
				^'%seq \)\(.*}\)/= ''\1'^$thunk^' \3/'}
			if {$c :eq $f} {
				c = `` \n {echo -- $f|sed 's/= ''\({\(|[^|]' \
					^'\+|\)\?\)\(.*}\)/= ''\1 %seq ' \
					^$thunk^' {\3}/'}
			}
			if {$c :eq $f} {
				c = `` \n {echo -- $f|sed 's/= ''\(.*\)''$' \
					^'/= ''{%seq '^$thunk^' {\1}}''/'}
			}
			fn-$name = `` \n {echo -- $c|sed 's/fn-[^ ]\+ = ' \
				^'''\(.\+\)''/\1/'|sed 's/''''/''/g'}
		}
	}
}

fn fec {|*|
	.d 'Report entry counts of annotated xs functions'
	.a '[-c]'
	.c 'system'
	if {~ $*(1) -c} {%objreset $fco; echo Cleared}
	let (lines = `{echo $($fco)|tr ' ' \n|grep -vx obj|sort}) {
		for l $lines {
			let ((n c) = <={%split : $l}) {
				printf '%-38s  %12d'\n $n $c
			}
		} | local (LC_ALL = C) sort | less -FX
	}
}

fn %enter {|name|
	let (v = <={%objget $fco $name 0}) {
		%objset $fco $name `($v+1)
	}
}

fn .annotate {
	if {~ $fco ()} {
		fco = <=%mkobj
	}
	if {%obj-isempty $fco} {
		for f (`` \n {vars -f}) {
			let (name = `{echo $f|cut -d' ' -f1|cut -c4-}) {
				if {!~ $name %advise %enter \
						%mkobj %obj* .obj*} {
					echo $name
					%advise $name '{%enter '$name'}'
				}
			}
		}
	}
}
