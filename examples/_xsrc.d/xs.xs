fn libedit {|*|
	.d 'Edit library function'
	.a 'NAME'
	.c 'xs'
	if {~ $#* 0} {
		.usage libedit | %wt-pager
	} else {
		.ensure-libloc
		~ $EDITOR () && throw error libedit '$EDITOR is unset'
		let ((file line) = <={~~ <={%objget $libloc $*} *:*}) {
			if {!~ $file ()} {
				$EDITOR +$line $file
			} else if {access -f ~/.local/bin/$*} {
				$EDITOR ~/.local/bin/$*
			} else {
				if {~ $WITH_TERMINAL ()} {
					throw error libedit 'not a function' \
						^' or in ~/.local/bin'
				} else {
					echo libedit: 'not a function' \
						^' or in ~/.local/bin' \
					| %wt-pager
				}
			}
		}
	}
}

fn parse {|*|
	.d 'Parse an xs expression'
	.a '[EXPRESSION]'
	.c 'xs'
	if {~ $#* 0} {
		escape {|fn-done| {while true {
			access -r /dev/stdin || done
			catch {|e| if {~ $e sigint} {
				done
			} else {
				printf %s\n $^e
			}} {
			let (c = <={~~ <={%parse 'xs: ' '  : '} \{*\}}) {
				if {!~ $c ()} {xs -nxc $c}}}
		}}}
	} else {xs -nxc $^*}
}

fn pp {|*|
	.d 'Prettyprint xs function'
	.a 'NAME'
	.c 'xs'
	if {~ $#* 0} {
		.usage pp
	} else {
		catch {|e|
			throw error pp 'not a function'
		} {
			%with-tempfile f {
				%pprint $* >$f
				list $f
			}
		}
	}
}

fn refresh-libloc {
	.d 'Refresh library location database.'
	.c 'xs'
	%rmobj $libloc
	libloc =
	rm -f ~/.cache/xslib/libloc
}

fn uh {
	.d 'Undo history'
	.c 'xs'
	!~ $history () && {
		let (li = `{cat $history|wc -l}) {
			history -d $li >/dev/null
			history -d `($li-1)
		}
	}
}

%prewrap vars

fn vars {|*|
	.d 'List environment'
	.a '[vars_OPTIONS]'
	.c 'xs'
	if {!~ $#* 0 && ~~ $* -*} {
		.usage vars
	} else {
		%_vars $* | less -UFXi -\# 5
	}
}

fn varss {|*|
	.d 'List environment w/o objects, arrays and xs utility vars'
	.a '[vars_OPTIONS]'
	.c 'xs'
	if {!~ $#* 0 && ~~ $* -*} {
		.usage varss
	} else {
		%_vars $* | grep -av -e '^'\xff \
			-e '^''_[ns]@[0-9]\+'' ' \
			-e '^''_p[12abrt]@[0-9]\+'' ' \
			-e '^prompt ' \
			-e '^_o[abp] ' \
			-e '^libloc ' | less -UFXi -\# 5
	}
}

fn val {|*|
	.d 'Print result of given xs(1) fragment'
	.a 'FRAGMENT'
	.c 'xs'
	echo -- <=$*
}

fn xs-man {
	.d 'Display xs manual'
	.c 'xs'
	%with-terminal xs-man {
		man xs
	}
}

fn xs-quickref {
	.d 'Display xs quick reference'
	.c 'xs'
	%with-terminal xs-quickref {{cat <<'EOF'
XS Quick Reference
	legend: ├ comment ┤ «metasyntactic variable» <character name>
		more-of-the-same…

special characters
------------------
# $ & ' ( ) ; \ ^ ` { | } <space> <tab> <newline>

character escapes
-----------------
\a \b \e \f \n \r \t
\xNN \MNN ├ M = [0..3], N = [0..f] ┤
\u'N…' ├ N = [0..f]; N… != 0 ┤

words
-----
<character>… ├ no specials; escapes honored ┤
«quoted word»

quoted words
------------
'<character>…' ├ escapes taken literally ┤
'<character>…''<character>…' ├ interior ' ┤

commands
--------
«cmd» <newline>
«cmd»
…
«cmd»; «cmd»; …

fragments
---------
{«command»}

comments
--------
# to end of line

line continuation
-----------------
start here \<newline>
and end here

lists
-----
() ├ empty list ┤
«word»
«word» «list» … ├ () «list» is «list» ┤

concatenation
-------------
«word1» ^ «word2» ├ same as «word1»«word2» ┤
«word» ^ ()  ├ same as () ┤
«list1» ^ «list2» ├ cross product ┤

names
-----
letters, digits, UTF-8 code points >\u'7f', non-special punctuation
 and escaped special characters (without restriction)

special names
-------------
fn-… ├ function definition ┤
set-… ├ settor function ┤

assignment operator
-------------------
<space>=<space>

assignment
----------
«name» «assignop» «list» ├ undefine «name» if «list» is empty ┤
(«name» …) «assignop»  «list»

subscripts
----------
«index»
«index1» ... «indexN»
«indexN» ... «index1»
«index» ...
... «index»

variable reference
------------------
$«name»
$«name»(«subscripts»)
$«variable_reference»

list length
-----------
$#«name»

flattened list
--------------
$^«name»

pattern
-------
* ├ match zero or more characters ┤
? ├ match exactly one character ┤
[«class»] ├ by «class» according to ed(1), but with ~ for negation ┤

pathname
--------
~ ├ expands to value of $home ┤
~«user» ├ expands to home directory path of «user» ┤

pattern match
-------------
~ «subject» «pattern» …

pattern extraction
------------------
~~ «subject» «pattern» …

arithmetic
----------
`( «expression» ) ├ infix operators +, -, *, /, % and **; simple variable     ┤
                  ├ reference (variable names may not include operator chars) ┤

command substitution
--------------------
` «fragment» ├ use $ifs for separators ┤
`` «separators» «fragment»

function definition
-------------------
fn «name» «fragment»
fn-«name» «assignop» «fragment»

lambda list
-----------
| «name» … |

lambda
------
«fragment»
{ «lambda_list» «command» … }

return value
------------
result «list»

logical operators
-----------------
«value1» && «value2»
«value1» || «value2»
! «value»

relational operators
--------------------
«value1» :lt «value2»
«value1» :le «value2»
«value1» :gt «value2»
«value1» :ge «value2»
«value1» :eq «value2»
«value1» :ne «value2»

here document
-------------
«fragment» <<«eof-marker»
«text» … ├ simple variables are substituted; $$ for literal $ ┤
«eof-marker»
«fragment <<'«eof-marker»'
«text» … ├ no substitutions ┤
«eof-marker»

here string
-----------
<<<'«text» ├ may span lines; no substitutions ┤ …'

process substitution
--------------------
<{ «command» …}
>{ «command» …}

binding
-------
«name» «assignop» «value»
«name» ├ «value» is () ┤
«binding»; «binding»

local variables
---------------
local ( «binding» ) «fragment»

lexical variables
-----------------
let ( «binding» ) «fragment»

conditionals
------------
if «condition» «fragment»
if «condition» «fragment» else «fragment»
switch «variable_reference» «cases» «fragment»
 ├ a «case» is «match_word» «fragments»; «cases» is a list of these; ┤
 ├ the final «fragment» executes when no «case» matches              ┤

vars and values
---------------
«var» «list»
«vars_and_values;» «vars_and_values»

loops
-----
while «condition» «fragment»
until «condition» «fragment»
for «vars_and_values» «fragment»
forever «fragment»

exceptions
----------
catch «catcher» «body» ├ «catcher» and «body» are «fragments» ┤
throw «kind»
throw «kind» «arg»…

signals
-------
signals-case «body» «handlers-alist»
 ├ «body» is a «fragment» ┤
 ├ «handlers-alist» is a list of «signal-name» «fragment» pairs ┤
signals = «signals-list»
 ├ «signals-list» is a list of «sigaction»«signal-name» ┤
 ├ «sigaction» is one of: ┤
 ├      -  Ignore here and in child ┤
 ├      /  Ignore here, but take default behavior in child ┤
 ├      .  Run predefined special handler ┤
 ├ (none)  Take default behavior ┤
raise «signal-name»

redirection
-----------
operator	action		descriptor    .  modifier	action
........	............	............  .  ..........	......
<		read		stdin         .  ◆[fd]		open
>		create		stdout        .  ◆[fd=]		close
>>		append		stdout        .  ◆[fd1=fd2]	dup
><		read/create	stdout
<>		read/replace	stdin
<>>		read/append	stdin
>><		read/append	stdout
|		pipe		stdout|stdin
EOF
	} | sed 's/├[^┤]\+┤/'^<=.%ad^\&^<=.%an^'/g' | %wt-pager}
}

fn help {|*|
	.d 'Help for xs function'
	.a 'NAME'
	.a '-c [CATEGORY]'
	.a '-l CATEGORY'
	.a '-h'
	.c 'help'
	if {~ $#* 0} {.usage help}
	let ( \
		fn-ext = {
			sed 's/{\.\(a\|c\|i\|d\|r\) [^}]*}/\n&\n/g'
		}; \
		fn-fmt = {
			sed 's/''''/''/g' | \
			sed 's/^{\.\(.\) ''\(.*\)''}$/\1: \2/' | \
			sed 's/''''/''/g' | \
			fold -s | awk -f <{cat <<'EOF'
/^(a|c|i|d|r|_): / {first=1;}
{if (first) {print; first=0;} else {print "    " $0}}
EOF
			}
		} \
		) {
		if {~ $*(1) -c && ~ $*(2) builtin} {
			-category-builtin
		} else if {~ $* -c} {
			switch $#* (
			1 {cat <{vars -f | ext | grep -e '^{\.c'} \
					<{echo 'c: builtin'} \
				| fmt | sort | uniq}
			2 {vars -f|grep '{\.c '''''^$*(2) \
				| ext | sed 's/^fn-[^ ]\+/\n&\n/g' \
				| grep -e '^\({\.\(a\|\d\|r\)\|fn-\)' \
				| sed 's/fn-\([^ ]\+\)/' \
					^'_: '^<=.%au^'\1'^<=.%an^'/g' \
				| fmt }
			)
		} else if {~ $*(1) -l} {
			if {~ $*(2) ()} {
				.usage help
			} else if {~ $*(2) builtin} {
				-list-builtin
			} else {
				vars -f|grep '{\.c '''''^$*(2) \
					| sed 's/^fn-\([^ ]\+\).*/\1/g' \
					| column
			}
		} else if {~ $* -h} {
			cat <<'EOF'
Legend
------
d: Description
a: Arguments
c: Category
r: Related
i: Informational
EOF
		} else if {~ $#* 1} {
			let (nm = $*(1); st) {
				st = <={vars -f|grep '^fn-'$nm'\s' | ext \
					| grep -e '^{\.\(a\|c\|i\|\d\|r\)' \
					| fmt}
				~ $^st '0 1 0 1 0' && {
					if {access -f ~/.local/bin/$nm} {
						grep -e '^#\.\(a\|c\|i\|' \
								^'\d\|r\)' \
							~/.local/bin/$nm \
							|sed 's/^#\.\(.\) ' \
								^'\(.*\)$/' \
								^'\1: \2/'
					} else if {! -help-builtin $nm} {
						echo 'no help for' $nm
						whats $nm
					}
				}
			}
		}
	} | less -iRFX
	true
}

fn lib {|*|
	.d 'List names of library functions'
	.a '-l  # sort by length, then name'
	.c 'help'
	.r 'liba libdoc libi'
	%with-terminal lib {let (fn-sf) {
		if {~ $* -l} {fn-sf = %asort} else {fn-sf = cat}
		vars -f | cut -c4- | cut -d' ' -f1 | grep -E '^(%|\.)' \
			| grep -v -e %prompt -e '^%_' | sf \
			| column -c `{tput cols} | %wt-pager
	}}
	# Ideally we'd hide all of the xs hook functions; not only %prompt.
}

fn liba {|*|
	.d 'Library function names apropos.'
	.a 'MATCH'
	.c 'help'
	.r 'lib libdoc libi'
	if {!~ $#* 1} {
		.usage liba
	} else {
		for f `{vars -f|cut -c4-|cut -d' ' -f1|grep -E '^(%|\.)' \
				|grep -v -e %prompt -e '^%_'|grep -F $*} {
			printf '%s'\t $f
			catch {echo '?'} {%header-doc $f}|head -1
		} | column -s \t -t|less -iRFXS
	}
}

fn libdoc {
	.d 'List documentation for all library functions.'
	.c 'help'
	.r 'liba libdoc libi'
	.ensure-libdoc
	%with-terminal libdoc {%wt-pager -rf ~/.cache/xslib/libdoc.$TERM}
}

fn libi {|*|
	.d 'Show information about a library function.'
	.a 'FUNCTION-NAME'
	.c 'help'
	.r 'liba libdoc libdoc'
	if {~ $#* 0} {
		.usage libi
	} else {
		.libi $*
	} | less -iRFX
}

fn luc {|*|
	.d 'List user commands'
	.a '-l  # sort by length, then name'
	.a '-s  # list commands on system paths'
	.a '-w  # include wrapped commands'
	.c 'help'
	.r 'luca'
	%with-terminal luc {
	let (al = <={%args $*}; fn-sf; fn-wf) {
		if {~ $al -l} {fn-sf = %asort} else {fn-sf = sort}
		if {~ $al -w} {fn-wf = cat} \
			else {fn-wf = {grep -v '{\.f [^}]*wrap[^}]*}'}}
		printf <=.%as^'@ ~/.xs*'^<=.%an^\n
		vars -f | wf \
			| grep -o '^fn-[^ ]\+' | cut -d- -f2- \
			| grep '^[a-z0-9]' | sf | column -c `{tput cols}
		access -f ~/bin/* && {
			printf <=.%as^'@ ~/bin'^<=.%an^\n
			find -L ~/bin -mindepth 1 -maxdepth 1 -type f \
				-executable | sf | xargs -n1 basename \
				| column -c `{tput cols}
		}
		if {~ $al -s} {
			printf <=.%as^'@ /usr/local/bin'^<=.%an^\n
			ls /usr/local/bin | sf | column -c `{tput cols}
			optbins = `{find /opt -type d -name bin}
			for d $optbins {
				printf <=.%as^'@ '^$d^<=.%an^\n
				ls $d | sf | column -c `{tput cols}
			}
		}
	} | %wt-pager -r }
}

fn luca {|*|
	.d 'User command names apropos.'
	.a 'MATCH'
	.c 'help'
	.r 'luc'
	if {!~ $#* 1} {
		.usage luca
	} else {
		for f `{vars -f|grep -o '^fn-[^ ]\+'|cut -d- -f2- \
					|grep '^[a-z0-9]'|grep -F -- $*} {
			printf '%s'\t $f
			var fn-^$f|sed 's/{\.d [^}]*}/\n&\n/g'|grep '^{\.d ' \
				|sed 's/''''/''/g' \
				|sed 's/^{\.\(.\) ''\(.*\)''}$/\1: \2/' \
				|sed 's/''''/''/g'|sed 's/^d: //'
		} | column -s \t -t|less -iRFXS
	}
}
