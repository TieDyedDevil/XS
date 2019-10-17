fn libedit {|*|
	.d 'Edit library function'
	.a 'NAME'
	.c 'xs'
	%with-terminal libedit {
	if {~ $#* 0} {
		.usage libedit | %wt-pager
	} else {
		.ensure-libloc
		let ((file line) = <={~~ <={%objget $libloc $*} *:*}) {
			if {!~ $file ()} {
				$EDITOR +$line $file
			} else {
				if {~ $WITH_TERMINAL ()} {
					throw error libedit 'not a function'
				} else {
					echo libedit: 'not a function' \
						| %wt-pager
				}
			}
		}
	}}
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
	.a '[-c] NAME'
	.c 'xs'
	if {~ $#* 0} {
		.usage pp
	} else {%with-terminal pp {
		let (syntax = text) {
			if {~ $*(1) -c} {
				syntax = xs
				* = $*(2 ...)
			}
			catch {|e|
				throw error pp 'not a function'
			} {
				%with-tempfile f {
					%pprint $* >$f
					list -s $syntax $f
				} | %wt-pager
			}
		}
	}}
}

fn refresh-libloc {
	.d 'Refresh library location database.'
	.c 'system'
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

fn xsqr {
	.d 'Display xs quick reference'
	.c 'xs'
	%with-terminal xsqr {{cat <<'EOF'
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
var-… ├ settor function ┤

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
`( «expression» ) ├ infix operators +, -, *, /, % and **;
  simple variable reference (variable names may not include operator chars) ┤

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
 ├ a «case» is «match_word» «fragments»; «cases» is a list of these;
   the final «fragment» executes when no «case» matches ┤

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
	} | %wt-pager}
}
