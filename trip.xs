# trip.es -- take a tour of es
# Invoke as "path-to-new-es < trip.es"

# this trip doesn't tour much of the code at all.  es needs a real
# set of regression tests, soon.

#es = $0
es = ./xs
echo tripping $es
tmp = /tmp/trip.$pid
rm -f $tmp

fn fail { |*|
	echo >[1=2] 'test failed:' $*
	exit 1
}

fn check { |*|
	if {!~ $#* 3} {
		echo too many args too check on test $1
		exit 1
	}
	if {!~ $2 $3} {
		fail $1
	}
}

fn errorcheck { |*|
	if {!~ $#* 3} {
		fail 'usage: errorcheck testname expected command'
	}
	if {!~ `` '' {$2>[2=1]} *^$3^*} {
		fail error message on $1':' $2
	}
}

fn expect { |*|
	echo >[1=2] -n expect $^*^': '
}

# lexical tests

errorcheck 'tokenizer error'	{$es -c 'echo hi |[2'} 'expected ''='' or '']'' after digit'
errorcheck 'tokenizer error'	{$es -c 'echo hi |[92=]'} 'expected digit after ''='''
errorcheck 'tokenizer error'	{$es -c 'echo hi |[a]'} 'expected digit after ''['''
errorcheck 'tokenizer error'	{$es -c 'echo hi |[2-'} 'expected ''='' or '']'' after digit'
errorcheck 'tokenizer error'	{$es -c 'echo hi |[2=99a]'} 'expected '']'' after digit'
errorcheck 'tokenizer error'	{$es -c 'echo hi |[2=a99]'} 'expected digit or '']'' after ''='''
errorcheck 'tokenizer error'	{$es -c 'echo ''hi'} 'eof in quoted string'


#
# blow the input stack
#

#if {
#	!~ hi `{
#		eval eval eval eval eval eval eval eval eval eval eval eval eval \
#		eval eval eval eval eval eval eval eval eval eval eval eval eval \
#		eval eval eval eval eval eval eval eval eval eval eval eval eval \
#		eval eval eval eval eval eval eval eval eval eval eval eval eval \
#		eval eval eval eval eval eval eval eval eval eval eval eval eval \
#		eval eval eval eval eval eval eval eval eval eval eval eval eval \
#		eval eval eval eval eval eval eval eval eval eval eval eval eval \
#		eval eval eval eval eval eval eval eval eval eval eval eval eval \
#		eval eval eval eval eval eval eval eval eval eval eval eval eval \
#		eval eval eval eval eval eval eval eval eval eval eval eval eval \
#		eval eval eval eval eval eval eval eval eval eval eval echo hi
#	}
#} { fail huge eval
#}

#
# umask
#

umask 0
> $tmp
x  =  `{ls -l $tmp}
if {!~ $x(1) *-rw-rw-rw-*} { fail umask 0 'produced incorrect result:' $x(1) }
rm -f $tmp
umask 027
> $tmp
y = `{ls -l $tmp}
if {!~ $y(1) *-rw-r-----*} { fail umask 027 'produced incorrect file:' $y(1) }
rm -f $tmp
if {!~ `umask 027 0027} { fail umask 'reported bad value:' `umask }

errorcheck 'bad umask' {umask bad} 'bad umask'
errorcheck 'bad umask' {umask -027} 'bad umask'
errorcheck 'bad umask' {umask 8} 'bad umask'

if {!~ `umask 027 0027} {
	fail bad umask changed umask value to `umask
}

#
# redirections
#

fn bytes { |*| for i : $* { let(x  =  `{wc -c $i}) echo $x(1) } }
echo foo > foo > bar
if {!~ `{bytes foo} 0} { fail double redirection created non-empty empty file }
if {!~ `{bytes bar} 4} { fail 'double redirection created wrong sized file:' `{bytes bar} }
rm -f foo bar
echo -n >1 >[2]2 >[1=2] foo
x  =  `` '' {cat 1}
if {!~ $#x 0} { fail 'dup created non-empty empty file:' `` '' {cat 1} }
if {!~ `` '' {cat 2} foo} { fail 'dup put wrong contents in file :' `` '' {cat 2} }
rm -f 1 2

expect error from cat, closing stdin
cat >[0=]

errorcheck 'redirection error' {cat>(1 2 3)} 'too many' 
errorcheck 'redirection error' {cat>()} 'null'

#
# exceptions
#

# Relies on old error mesages
#check catch/retry \
#	`` '' {
#		let (x  =  a b c d e f g)
#			catch @ e {
#				echo caught $e
#				if {!~ $#x 0} {
#					x  =  $x(2 ...)
#					throw retry
#				}
#				echo never succeeded
#			} {
#				echo trying ...
#				eval '@'
#				echo succeeded -- something''''s wrong
#			} 
#	} \
#'trying ...
#caught error $&parse {@}:1: syntax error
#trying ...
#caught error $&parse {@}:1: syntax error
#trying ...
#caught error $&parse {@}:1: syntax error
#trying ...
#caught error $&parse {@}:1: syntax error
#trying ...
#caught error $&parse {@}:1: syntax error
#trying ...
#caught error $&parse {@}:1: syntax error
#trying ...
#caught error $&parse {@}:1: syntax error
#trying ...
#caught error $&parse {@}:1: syntax error
#never succeeded
#'
#
#
# heredocs and herestrings
#

bigfile = /tmp/big.$pid
od $es | sed 5000q > $bigfile
abc = (this is a)
x = ()
result = 'this is a heredoc
this is an heredoc
'
if {!~ `` '' {<<[5] EOF cat <[0=5]} $result} {fail unquoted heredoc}
$abc heredoc$x
$abc^n $x^here$x^doc
EOF
{if {!~ `` \n cat '	'} {fail quoted heredoc}} << ' '
	
 

<<<[9] ``''{cat $bigfile} \
{
 	if{!~ ``''{cat <[0=9]}``'' cat}{fail large herestrings}
} < \
$bigfile

rm -f $bigfile

if {!~ `{cat<<eof
$$
eof
} '$'} {
	fail quoting '$' in heredoc
}

errorcheck 'incomplete heredoc'	{$es -c 'cat<<eof'} 'pending' 
errorcheck 'incomplete heredoc'	{$es -c 'cat<<eof'\n} 'incomplete'

errorcheck 'bad heredoc marker'	{$es -c 'cat<<(eof eof)'} 'not a single literal word'
errorcheck 'bad heredoc marker'	{$es -c 'cat<<'''\n''''\n} 'contains a newline'
