fn _fec {}
fn fec {|*|
	.d 'Report entry counts of annotated xs functions'
	.a '[-c]  # clear counts'
	.c 'system'
	.r 'annotate'
	if {~ $*(1) -c} {%objreset $fco; echo Cleared}
	if {!grep -q '{_enter _fec}' <{var fn-_fec}} {echo 'Not annotated'}
	let (lines = `{echo $($fco)|tr ' ' \n|grep -vx obj|sort}) {
		for l $lines {
			let ((n c) = <={%split : $l}) {
				printf '%-38s  %12d'\n $n $c
			}
		} | local (LC_ALL = C) sort | less -iFX
	}
}

# This is the annotation we use to count the number of times that a
# user-defined function has been entered since the annotation.
# The counts are stored in the environment, with all that implies.
fn _enter {|name|
	let (v = <={%objget $fco $name 0}) {
		%objset $fco $name `($v+1)
	}
}

fn annotate {|*|
	.d 'Annotate user-defined xs functions'
	.a '[-f]  # force'
	.c 'system'
	.r 'fec'
	if {~ $fco ()} {
		fco = <=%mkobj
	}
	if {{~ $*(1) -f} || {%obj-isempty $fco}} {
		%without-cursor {
			for f (`` \n {vars -f}) {
				let (name = `{echo $f|cut -d' ' -f1|cut -c4-}) {
					if {!~ $name %advise _enter \
							%mkobj %obj* .obj*} {
						printf \r%s%s $name `.ed
						%advise $name '{_enter '$name'}'
					}
				}
			}
			printf \r%sAnnotated\n `.ed
		}
	}
}
