# User ps
fn .pu {|*|
	let (flags) {
		while {~ $*(1) -*} {
			~ $*(1) -[fFcyM] && flags = $flags $*(1)
			* = $(2 ...)
		}
		ps -Hlj $flags -U^`{if {~ $#* 0} {echo $USER} else {echo $*}}
	}
}

# Set framebuffer size
fn .fbset {|*|
	if {~ $TERM linux} {fbset -a -g $* $* 32} else {echo 'not a vt'}
}

# Help tags
fn .d {|*|} # docstring
fn .c {|*|} # category
fn .a {|*|} # argstring

# Create a random prompt at shell startup
fn .xsin-rp {%prompt; rp; _n@$pid = 0}

# Web lookups
fn .web-query {|site path query|
	if {~ $#query 0} {
		web-browser $site
	} else {
		let (q) {
			q = `{echo $^query|sed 's/\+/%2B/g'|tr ' ' +}
			web-browser $site^$path^$q
		}
	}
}

# Greetings and salutations
fn .herald {
	let (fn-nl = {printf \n}; fn-isconsole = {~ `tty *tty*}) {
		.as; cookie; .an; nl
		isconsole && {on; nl; net; nl; thermal; battery; load; nl}
		.ab; where; .an
	}
}
