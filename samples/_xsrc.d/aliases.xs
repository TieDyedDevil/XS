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
	env TERM=st /usr/bin/mutt $*
}
fn on {
	.d 'List console logins'
	.c 'alias'
	who -Huw
}
fn open {|*|
	.c 'alias'
	xdg-open $*
}
fn sysmon {
	.d 'View Monitorix stats'
	.c 'alias'
	web http://localhost:8080/monitorix
}
fn tsm {|*|
	.d 'Terminal session manager'
	.a '[tsm_OPTIONS]'
	.c 'alias'
	%preserving-title ~/bin/tsm $*
}
%prewrap vars
fn vars {|*|
	.d 'List environment'
	.c 'alias'
	%_vars $* | less -RFXi
}
fn varss {|*|
	.d 'List environment w/o objects, arrays and xs utility vars'
	.c 'alias'
	%_vars $* | grep -av -e '^'\xff \
		-e '^''_[ns]@[0-9]\+'' ' \
		-e '^''_p[12abrt]@[0-9]\+'' ' \
		-e '^prompt ' \
		-e '^_o[abp] ' \
		-e '^libloc ' | less -RFXi
}
fn worms {|*|
	.d 'Display worms'
	.a '[worms_OPTIONS]'
	.c 'alias'
	%with-quit {
		/usr/bin/worms -n 7 -d 50 $*
	}
}
