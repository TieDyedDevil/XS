fn touchscreen {|*|
	.d 'Touchscreen control'
	.a '[on|off]'
	.c 'wm'
	let (tsid = `{xinput --list|grep Touchscreen|grep -o 'id=[0-9]\+' \
		|cut -d= -f2}; sw) {
		~ $* <={%prefixes on} && sw = --enable
		~ $* <={%prefixes off} && sw = --disable
		~ $sw () && throw error touchscreen 'on or off'
		!~ $tsid () && xinput $sw $tsid
	}
}
