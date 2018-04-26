fn ag {|*|
	.d 'Search tree for pattern in files'
	.a '[ag_OPTIONS] PATTERN [DIRECTORY]'
	.c 'alias'
	/usr/bin/ag --pager='less -iRFX' $*
}
fn c {
	.d 'Clear screen'
	.c 'alias'
	clear
}
fn calc {|*|
	.d 'Evaluate arithmetic expression'
	.a 'nickle_EXPRESSION'
	.c 'alias'
	~ $#* 0 || nickle -e $*
}
%cfn {%have mandelbulber} mb {|*|
	.c 'alias'
	mandelbulber $*
}
%cfn {%have mandelbulber2} mb2 {|*|
	.c 'alias'
	mandelbulber2 $*
}
fn mutt {|*|
	.c 'alias'
	# mutt won't override st colors
	%with-terminal env TERM=st /usr/bin/mutt $*
}
fn sysmon {
	.d 'View Monitorix stats'
	.c 'alias'
	web http://localhost:8080/monitorix
}
