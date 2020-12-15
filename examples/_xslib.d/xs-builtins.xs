-xs-help = <={%mkdict (
	.	<={%mkdict (
		.d 'Source a file'
		.a '[-einvx] FILE ARG...'
		.c 'builtin'
		)}
	access	<={%mkdict (
		.d 'Test path(s) for accessibility'
		.a '[-rwx] [-fdcblsp] PATH...  # true for each accessible PATH'\n\
		^'PATH...  # true for existence of each PATH'\n\
		^'-n NAME [OPT...] PATH...  # true for each path having NAME'\n\
		^'-1 [OPT...] PATH...  # return first satisfying PATH or ()'\n\
		^'-1e [OPT...] PATH...  # throw error if no satisfying PATH'
		.c 'builtin'
		)}
	alias	<={%mkdict (
		.d 'Define an an alias'
		.a 'NAME EXPANSION...'
		.c 'builtin'
		)}
	catch	<={%mkdict (
		.d 'Run code with caught exceptions'
		.a 'CATCHER BODY  # exception passed as CATCHER argument'
		.c 'builtin'
		)}
	cd	<={%mkdict (
		.d 'Set working directory'
		.a 'DIRECTORY'\n\
		^'(none)  # same as cd $home'
		.c 'builtin'
		)}
	dirs	<={%mkdict (
		.d 'Directory stack'
		.a '(none)  # display'\n\
		^'-c  # clear'
		.r 'pushd popd'
		.c 'builtin'
		)}
	echo	<={%mkdict (
		.d 'Print args space-separated'
		.a '[-n] [--] ARG...'
		.c 'builtin'
		)}
	escape	<={%mkdict (
		.d 'Lexical escape'
		.a 'LAMBDA  # |fn-ESCAPE_FN|'
		.c 'builtin'
		)}
	eval	<={%mkdict (
		.d 'Evaluate'
		.a 'WORD...  # taken as a single executable text'
		.c 'builtin'
		)}
	exec	<={%mkdict (
		.d 'Execute'
		.a 'COMMAND  # replace xs with COMMAND'\n\
		^'REDIRECTION(S)  # apply redirections'
		.c 'builtin'
		)}
	exit	<={%mkdict (
		.d 'Terminate xs'
		.a '[STATUS]  # default 0'
		.c 'builtin'
		)}
	false	<={%mkdict (
		.d 'result 1'
		.c 'builtin'
		)}
	fn	<={%mkdict (
		.d 'Define function'
		.a 'NAME LAMBDA'
		.c 'builtin'
		)}
	for	<={%mkdict (
		.d 'Iterate over list(s)'
		.a 'VARS_AND_VALUES FRAGMENT'
		.c 'builtin'
		)}
	forever	<={%mkdict (
		.d 'Infinite loop'
		.a 'FRAGMENT'
		.c 'builtin'
		)}
	fork	<={%mkdict (
		.d 'Run command in subshell'
		.a 'COMMAND'
		.c 'builtin'
		)}
	history	<={%mkdict (
		.d 'Show/manage command history'
		.a '(none)  # show'\n\
		^'NUMBER  # show NUMBER most recent'\n\
		^'-c  # clear history'\n\
		^'-d NUMBER  # delete entry NUMBER'\n\
		^'-n|-y  # disable/enable'
		.c 'builtin'
		)}
	if	<={%mkdict (
		.d 'Conditional'
		.a 'CONDITION FRAGMENT [else FRAGMENT]'
		.c 'builtin'
		)}
	jobs	<={%mkdict (
		.d 'List background jobs'
		.c 'builtin'
		)}
	let	<={%mkdict (
		.d 'Lexical binding'
		.a 'BINDINGS FRAGMENT'
		.c 'builtin'
		)}
	limit	<={%mkdict (
		.d 'Display/alter process resource limits'
		.a '[-h] [RESOURCE [LIMIT]]'
		.c 'builtin'
		)}
	local	<={%mkdict (
		.d 'Dynamic binding'
		.a 'BINDINGS FRAGMENT'
		.c 'builtin'
		)}
	map	<={%mkdict (
		.d 'Map collecting results'
		.a 'ACTION LIST'
		.c 'builtin'
		)}
	omap	<={%mkdict (
		.d 'Map collecting outputs'
		.a 'ACTION LIST'
		.c 'builtin'
		)}
	pause	<={%mkdict (
		.d 'Suspend execution until xs receives a signal'
		.c 'builtin'
		)}
	popd	<={%mkdict (
		.d 'Pop directory stack to set working directory'
		.r 'dirs pushd'
		.c 'builtin'
		)}
	printf	<={%mkdict (
		.d 'Formatted print'
		.a 'FORMAT [ARG...]'
		.c 'builtin'
		)}
	pushd	<={%mkdict (
		.d 'Push working directory to stack and change.'
		.a 'DIR'\n\
		^'(none)  # swap top two entries, changing directory'
		.r 'dirs pushd'
		.c 'builtin'
		)}
	raise	<={%mkdict (
		.d 'Raise a signal to be handled by signals-case'
		.a 'SIGNAME'
		.c 'builtin'
		)}
	read	<={%mkdict (
		.d 'Read a line from standard input, stripping newline'
		.c 'builtin'
		)}
	result	<={%mkdict (
		.d 'Return value(s)'
		.a 'VALUE...'
		.c 'builtin'
		)}
	signals-case <={%mkdict (
		.d 'Bind signal handlers'
		.a 'FRAGMENT HANDLERS_ALIST'
		.c 'builtin'
		)}
	switch	<={%mkdict (
		.d 'Multiway conditional'
		.a 'VALUE [CASE ACTION]... [DEFAULT_ACTION]'
		.c 'builtin'
		)}
	throw	<={%mkdict (
		.d 'Throw exception'
		.a 'EXCEPTION ARG...'
		.c 'builtin'
		)}
	time	<={%mkdict (
		.d 'Print real, user and system time consumed by command'
		.a 'COMMAND [ARG...]'
		.c 'builtin'
		)}
	true	<={%mkdict (
		.d 'result 0'
		.c 'builtin'
		)}
	umask	<={%mkdict (
		.d 'Display/set umask'
		.a '[MASK]'
		.c 'builtin'
		)}
	until	<={%mkdict (
		.d 'Conditional loop'
		.a 'TEST BODY'
		.c 'builtin'
		)}
	unwind-protect
		<={%mkdict (
		.d 'Run body with cleanup'
		.a 'BODY CLEANUP'
		.c 'builtin'
		)}
	var	<={%mkdict (
		.d 'Print definition of var(s)'
		.a 'VAR...'
		.c 'builtin'
		)}
	vars	<={%mkdict (
		.d 'Print definition of variables'
		.a '[-vfs] [-epi] [-a]'
		.c 'builtin'
		)}
	wait	<={%mkdict (
		.d 'Wait for child process to exit'
		.a '[PID]'
		.c 'builtin'
		)}
	whats	<={%mkdict (
		.d 'Identify command(s) by pathname, primitive or fragment'
		.a 'COMMAND...'
		.c 'builtin'
		)}
	while	<={%mkdict (
		.d 'Conditional loop'
		.a 'TEST BODY'
		.c 'builtin'
		)}
	# other
	let	<={%mkdict (
		.d 'Introduce lexical binding(s)'
		.a '( BINDING_LIST ) FRAGMENT'
		.c 'builtin'
		)}
	local	<={%mkdict (
		.d 'Introduce dynamic binding(s)'
		.a '( BINDING_LIST ) FRAGMENT'
		.c 'builtin'
		)}
	fn	<={%mkdict (
		.d 'Define function'
		.a 'NAME LAMBDA'
		.c 'builtin'
		)}
	'$^'	<={%mkdict (
		.d 'Flatten list'
		.a 'LIST'
		.c 'builtin'
		)}
	\^	<={%mkdict (
		.d 'Concatenate words'
		.a 'WORD ◆ WORD  # infix'
		.c 'builtin'
		)}
	\~	<={%mkdict (
		.d 'Match'
		.a 'SUBJECT PATTERN...'
		.a '( SUBJECT... ) PATTERN...'
		.c 'builtin'
		)}
	'~~'	<={%mkdict (
		.d 'Extract'
		.a 'SUBJECT PATTERN...'
		.a '( SUBJECT... ) PATTERN...'
		.c 'builtin'
		)}
	'`('	<={%mkdict (
		.d 'Arithmetic substitution'
		.a 'EXPRESSION )  # *, /, %, +, - w/constants & simple vars'
		.c 'builtin'
		)}
	\`	<={%mkdict (
		.d 'Command substitution'
		.a 'FRAGMENT'
		.c 'builtin'
		)}
	'``'	<={%mkdict (
		.d 'Command substitution'
		.a 'SEPARATORS FRAGMENT'
		.c 'builtin'
		)}
	'&&'	<={%mkdict (
		.d 'Sequential AND'
		.a 'EXPRESSION ◆ EXPRESSION  # infix'
		.c 'builtin'
		)}
	'||'	<={%mkdict (
		.d 'Sequential OR'
		.a 'EXPRESSION ◆ EXPRESSION  # infix'
		.c 'builtin'
		)}
	\!	<={%mkdict (
		.d 'Logical NOT'
		.a 'EXPRESSION'
		.c 'builtin'
		)}
	':lt'	<={%mkdict (
		.d 'Relation <'
		.a 'EXPRESSION ◆ EXPRESSION  # infix'
		.c 'builtin'
		)}
	':gt'	<={%mkdict (
		.d 'Relation >'
		.a 'EXPRESSION ◆ EXPRESSION  # infix'
		.c 'builtin'
		)}
	':eq'	<={%mkdict (
		.d 'Relation ='
		.a 'EXPRESSION ◆ EXPRESSION  # infix'
		.c 'builtin'
		)}
	':ne'	<={%mkdict (
		.d 'Relation ≠'
		.a 'EXPRESSION ◆ EXPRESSION  # infix'
		.c 'builtin'
		)}
	':le'	<={%mkdict (
		.d 'Relation ≤'
		.a 'EXPRESSION ◆ EXPRESSION  # infix'
		.c 'builtin'
		)}
	':ge'	<={%mkdict (
		.d 'Relation ≥'
		.a 'EXPRESSION ◆ EXPRESSION  # infix'
		.c 'builtin'
		)}
	'<<'	<={%mkdict (
		.d 'Here document'
		.a 'DELIMITER'\n\
		^'''DELIMITER'''
		.c 'builtin'
		)}
	'<<<'	<={%mkdict (
		.d 'Here string'
		.a 'TEXT'
		.c 'builtin'
		)}
	'<{'	<={%mkdict (
		.d 'Process substitution, read'
		.a 'FRAGMENT }'
		.c 'builtin'
		)}
	'>{'	<={%mkdict (
		.d 'Process substitution, write'
		.a 'FRAGMENT }'
		.c 'builtin'
		)}
	\<	<={%mkdict (
		.d 'Redirect'
		.a 'FILE'
		.c 'builtin'
		)}
	\>	<={%mkdict (
		.d 'Redirect'
		.a 'FILE'
		.c 'builtin'
		)}
	'>>'	<={%mkdict (
		.d 'Redirect'
		.a 'FILE'
		.c 'builtin'
		)}
	'><'	<={%mkdict (
		.d 'Redirect'
		.a 'FILE'
		.c 'builtin'
		)}
	'<>'	<={%mkdict (
		.d 'Redirect'
		.a 'FILE'
		.c 'builtin'
		)}
	'<>>'	<={%mkdict (
		.d 'Redirect'
		.a 'FILE'
		.c 'builtin'
		)}
	'>><'	<={%mkdict (
		.d 'Redirect'
		.a 'FILE'
		.c 'builtin'
		)}
	\|	<={%mkdict (
		.d 'Pipe'
		.a 'COMMAND ◆ COMMAND  # infix'
		.c 'builtin'
		)}
	\;	<={%mkdict (
		.d 'Sequence COMMANDs; delimit LISTs and BINDINGs'
		.c 'builtin'
		)}
	\^	<={%mkdict (
		.d 'Concatenate words'
		.a 'WORD ◆ WORD  # infix'
		.c 'builtin'
		)}
	\$	<={%mkdict (
		.d 'Variable value'
		.a 'NAME'\n\
		^'( CONSTRUCTED_NAME )  # not on LHS of assignment'\n\
		^'NAME ( INDEX... )  # not on LHS of assignment'
		.c 'builtin'
		)}
	\=	<={%mkdict (
		.d 'Assignment (space-separated on both sides)'
		.a 'NAME = VALUE'\n\
		^'( NAME... ) = VALUE...'
		.c 'builtin'
		)}
	\&	<={%mkdict (
		.d 'Background COMMAND'
		.a '# suffix'
		.c 'builtin'
		)}
	)
}

fn -list-builtin {
	# List names of all xs builtins.
	for k <={%objkeys $-xs-help} {
		printf '%s'\n $k
	} | column
}

fn -category-builtin {
	# Print help for all xs builtins.
	for k <={%objkeys $-xs-help} {
		printf '_: %s%s%s'\n <=.%au $k <=.%an
		-help-builtin $k | grep -v '^c: '
	}
}

fn -help-builtin {|*|
	# Print help for xs builtin. Return true on success.
	let (md = <={%objget $-xs-help $*}; found = false) {
		!~ $md () && {
			for t (d a r c) {
				let (i = <={%objget $md .^$t}) {
					!~ $i () && {
						printf '%s: %s'\n $t $i \
							| awk -f <{cat <<'EOF'
/^.: / { tag = $1; print $0; next; }
// { print tag " " $0; }
EOF
								}
						found = true
					}
				}
			}
		}
		$found
	}
}
