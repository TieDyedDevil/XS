xs Tutorial
===========

`xs` is an extensible shell. Like other shells with which you're no
doubt familiar, `xs` can be used to run programs and scripts. But `xs`
is extensible. Parts of `xs` are written in `xs`. You can take advantage
of this by writing replacements for those parts to augment or modify
the behavior of `xs`. That's the "extensible" part.

Before we delve into `xs`'s extensibility, though, we need to take a
look at basic operations. Much of `xs` will seem familiar, but there are
enough differences from the shell you usually use to warrant a quick tour.

Perhaps the biggest difference between `xs` and traditional shells is that
`xs` has different rules for how data gets passed around in scripts that
you write. Traditional shells provide multiple ways to quote and evaluate
data; `xs` is much simpler. While you might think that it's better to
have more choices, you've probably questioned that wisdom when trying
to figure out how to deal with multiple levels of quoting and evaluation.

In `xs`, as in other shells, a word is formed from a sequence of
constituent characters. Unlike other shells, `xs` leaves many punctuation
characters available as word constituents. Therefore, these are all
valid words in `xs`:

```
  simple
  camelCase
  [bracketed]
  dotted.word
  1time
  *+,-./:=?@[]_~"
```

The final example is a word composed of all the non-special punctuation. I
don't know why you'd want to, but you *could* use that as a variable name:

```
; *+,-./:=?@[]_~" = 'I don''t even know...'
; echo $(*+,-./:=?@[]_~")
```

There are a few things to note in the preceding example:

    * The `xs` prompt is `;`. The man page explains this. Don't worry:
      you can change the prompt.
    * Words are quoted using `'`, which is quoted by doubling it.
      That's everything you need to know about `xs` quoting. Take a
      moment, if you will, to compare that to what you know about
      quoting in other shells.
    * The assignment operator `=` is always surrounded by spaces.
      Without the spaces, `=` becomes a word constituent. Indeed, this
      is the case in the `*+,-./:=?@[]_~"` word.
    * `"` is also a word constituent. This might seem odd at first, so
      I'll remind you: words in `xs` are quoted *only* using `'`.
    * As in other shells, you use `$` to dereference a variable. This
      example also needs to enclose the variable name in `(` and `)`.
      I'll talk more about this later.

In addition to quoting with `'`, you can use `\` to escape certain
characters. Here again, `xs`'s treatment differs somewhat from the
behavior you've come to expect from other shells. In `xs`, `\` is used
to escape the "special" characters:

```
# $ & ´ ( ) ; < > \ ^ ` { | } <space> <tab>
```

`xs` also recognizes escapes for a subset of characters that don't
have a printable glyph, i.e.:

    * \a <alert>
    * \b <backspace>
    * \e <escape>
    * \f <form-feed>
    * \n <newline>
    * \r <carriage return>
    * \t <tab>

as well as allowing you to spell out single-byte characters by their
code points in hexadecimal and octal notation:

    * \xNN where N is a hex digit
    * \MNN where M is {0..3} and N is an octal digit

You can also write Unicode characters (most of which are represented
by multiple bytes) using their 16-bit or 32-bit code points:

    * \uNNNN where N is a hex digit
    * \UNNNNNNNN where N is a hex digit

It's an error in `xs` to use `\` except as noted above. In the shell
you usually use, applying `\` to escape some other character simply
yields the escaped character. In `xs`, this happens:

```
; echo \j
columns 0-0 bad backslash escape
```

Do you remember the rule for quoting with `'`? Everything inside
`'...'` is quoted; escapes don't get expanded. Thus:

```
; echo 'label:\tThis is unusual.'
label:\tThis is unusual.
```

In `xs` you'd write:

```
; echo label:\t'This is unusual.'
label:  This is unusual.
```
or:

```
; echo label:\tThis\ is\ unusual.
label:  This is unusual.
```

In most shells, the underlying data type is a string and all of the
shell's machinery is designed around doing useful manipulations of this
data. You probably understand well the headaches this can cause when a
word contains whitespace.

In `xs` the underlying data type is a list. Every word in a list
retains its identity as a word, regardless of whether the word contains
whitespace.

For example, this `xs` code assigns a four-element list to `a`:

```
; a = foo a\ word\ with spaces 'another word' bar
```

The words in the list are

    * foo
    * 'a word with spaces'
    * 'another word'
    * bar

You can pass the variable `a` to a function; it will remain a
four-element list despite the blanks that are part of the second and third
words. There's no need for special quoting and unquoting conventions as
in other shells.

You can select elements of a list using subscript notation. For example:

```
; echo $a(3)
another word
```

Subscripts start at one. It's an error to specify a subscript less than 1.

You may specify multiple indices:

```
; echo $a(1 4)
foo bar
```

In this example, the result is a two-element list.

You can use `...` in a subscript list to specify a range. For example:

```
; l = a b c d e f g h i j
; echo $l(4 ... 6)
d e f
```

Either end of the range may be open:

```
; echo $l(... 3)
a b c
; echo $l(7 ...)
g h i j
```

Reversing the indices of a range yields the specified elements in
reverse order:

```
; echo $l(6 ... 4)
f e d
```

Specifying an index greater than the number of list elements yields the
empty list:

```
; echo $l(11)

```

While we're on the subject, let's consider lists and empty lists. Lists
in `xs` are always one-dimensional; a list can't contain another
list. This makes an empty list "disappear" when it's contained within
a list. Returning to our subscript examples:

```
; m = $l(1 11 2 11 11 11)
; echo $m
a b
; echo $#m
2
```

Even though we specified six indices, four of these indexed past the
end of `$l` and yielded empty lists.

If you need an empty placeholder in a list, use an empty word:

```
; q = a '' b '' '' c
; echo $q
a  b   c
; echo $# q
```

Again, contrast the above with:

```
; r = a () b () () c
; echo $r
a b c
; echo $#r
3
```

Subscripts may not be used on the left-hand side of an assignment:

```
; l(3) = 99
columns 2-2 syntax error, unexpected SUB, expecting NL or ENDFILE
```

Here are two more things you can do with lists:

```
; echo $#l
10
; echo $^l
a b c d e f g h i j
```

$#<name> returns the number of items in a list. $^<name> returns a
one-element list composed of all the items in the original list,
separated with spaces. Let's make that a bit more clear:

```
; m = $^l
; echo $m
a b c d e f g h i j
; echo $#m
1
```

`xs` splits text into words delimited by a field separator; any character
not matching a field separator is part of a word; a character matching
a field separator ends the word and begins a new word with the next
non-separator character. In `xs` the field separators are determined by
the value of `$ifs`, which normally contains <space>, <tab> and <newline>
(or, in `xs`: `\ \t\n`).

Now that we've introduced `$ifs`, we can turn our attention to the
backquote (`) operator. As in other shells, backquote captures the
output of a command or function. The syntax is slightly different that
what you've seen elsewhere:

```
; file_list = `ls
```

captures a list of file names in the current directory. You'll note that
there's no closing backquote as in other shells; you're probably wondering
how to capture the output of a command that has more than one word. In
`xs` we use a "program fragment":

```
; file_list = `{ls a*}
```

A program fragment is simply a group of commands wrapped in braces. A
program fragment may appear in an `xs` program anywhere you can use a
word. Thus the above example captures a list of all files beginning with
the letter "a".

Of course, because the default `$ifs` includes a space, any filename
containing spaces will be split into multiple words. That's normally
not what you'd like. As in other shells, the solution is to temporarily
replace the value of `$ifs` with just a newline. This would work:

```
; save_ifs = $ifs
; ifs = \n
; file_list = `ls
; ifs = $save_ifs
```

However, this can be simplified to:

```
; file_list = `` \n ls
```

Think of (``) as "backquote with temporary $ifs."

`xs` captures the status of a backquote command in the `$bqstatus`
variable. If the command is a pipeline, `$bqstatus` contains a return
code for each command in the pipeline.

True values in `xs` are `0`, `()` and `''`. Everything else is treated
as false.

A list evaluates true in `xs` only if all of the elements are true:

```
; if {result 0 () ''} {echo yes} else {echo no}
yes
; if {result 0 1 0} {echo yes} else {echo no}
no
```

When `xs` evaluates a list, it tries to take the first word as a
command. In the previous example, we used `result` as the command;
this simply returns its arguments.

At times it may be desirable to construct and execute a program
fragment. One such use might be to construct a Unicode character from
a code point computed at run time:

```
; echo `{{ |cp| eval echo '\u'$cp} 01dd}
ǝ
```

Looking at the above example from the inside out, we're constructing
a word like `\uNNNN`. This is how `xs` names a Unicode code point. The
value of `$cp` is lambda-bound; that's the `|cp|` notation in the inner
program fragment. `eval` expects a string, but `\uNNNN` is a word. `echo`
does what it always does: it prints a string. `eval` parses and evaluates
the given text, producing the `ǝ` as a word. Now look at the two program
fragments. The inner fragment, the lambda expression, is in the command
position; `01dd` is its argument, which gets bound to `cp` in the lambda
list. The backquote says "run this command." Finally, the leftmost `echo`
prints the `ǝ` character.

A statement in `xs` is simply a command followed by the command's
arguments. A statement is terminated by any of:

    * a newline
    * a semicolon
    * the closing brace of a program fragment
    * a "special" character (see above)

Note that it's the most restrictive syntactic feature that determines
the end of a statement. Consider this code:


```
{ foo a b c; bar x y
  qux 17 39 }
```

The `foo` statement ends at `;`, the `bar` statement ends at the newline
and the `qux` statement ends at `}`.

The following are not equivalent:

```
{ bagley parsimony fletch
  grackle }
```

and

```
{ bagley parsimony fletch grackle }
```

The former is two separate statements; the latter only one. We can, however, rewrite the first to be equivalent to the second by using line continuation:

```
{ bagley parsimony fletch \
  grackle }
```

The backslash-newline sequence reads as a blank space.

Parentheses may be used to bound a list. A list so bounded may span
newlines. The following assignments are all equivalent:

```
l = a b c d e f
l = a b c \
    d e f
l = (a b c
     d e f)
```

Remember, too, that `xs` lists are flat (that is: alway a list; never
a tree) and that empty lists "disappear" as a component of a list. The
following are equivalent:

```
m = (a b (c d (e) () f))
m = a b c d e f
m = ((((a b c d e f))))
```

Also, a list is not a program fragment, nor vice versa. Consider:

```
; (echo 1
   echo 2)
1 echo 2
; {echo 1
   echo 2}
1
2
```

The above example also illustrates how `xs`'s input reader handles a
continuation line. In both cases we typed an unfinished statement on
the first line; `xs` responded by printing its continuation prompt,
which is by default empty.

We've seen that a command may be a program (e.g. `ls`) or a lambda. A
lambda is just an unnamed `xs` function. We can also name `xs`
functions. The simplest case is to name a variable prefixed by `fn-`:

```
fn-ll = ls -l
```

You can also use the `fn` keyword to define a named `xs` function. This
is exactly equivalent to the previous example:

```
fn ll {ls -l}
```

A program not in a directory on `$PATH` may be used as a command by
naming an absolute or relative path to the program. In the case of a
relative path, `xs` differs from many other shells by requiring that
the path begins with a `.` (dot).

`xs` has all of the usual control-flow constructs, plus a few that you
don't usually see in shells.

The simplest control flow is a sequence. `xs` evaluates one statement
after another. Statements may be separated by a newline or a `;`.

Then there's conditional sequencing, provided by the familiar `&&` and
`||` operators. `&&` evaluates the statement to its right only if the
statement to its left has a true return code. `||` evaluates the statement
to its right only if the statement to its left has a false return code.

The `!` operator negates the return code of the statement to its right. As
in most programming languages, `!` has higher precedence than the other
boolean operators.

Like other shells, `xs` has wilcard matching, more commonly referred to
as "globbing". `*` and `?` match any sequence of characters (including
an empty sequence) or any individual character, respectively, in a
filename. `*` and `?` do not match `.` at the beginning of a filename,
nor do they match the `/` path separator.

Characters bracketed by `[` and `]` form a class that matches any one
character between the brackets. A negative class, i.e. a class that
matches any character *not* listed, is introduced by a `~` (*not* `^`
as in other shells) immediately following the open bracket.

Remember that there are no special characters within `'...'` in xs.

For the case where you'd like to match something other other than
a filename, `xs` provides a match operator. The syntax of the match
operator is:

```
~ <subject> <pattern>...
```

where <subject> is typically a variable, a backquote expression or other
statement that produces a string value. The <subject> is followed by one
or more patterns. `xs` does not match patterns against filenames in this
case; there's no need to (nor should you) quote the <pattern>s. (However,
a literal wilcard in the <subject> *is* expanded as described in the
previous paragraphs.)

You can specify the empty list as a pattern. But remember how `xs`
collapses empty lists within a list: you can't match *either* a pattern
or an empty list. This expression, for example, matches *only* `f?b`:

```
~ $v f?b ()
```

The pattern match operator returns true if <subject> matches any of
the <pattern>s. In the case where <subject> is a list, we obtain a true
result if any of the <subject>s match any of the <pattern>s. All in all,
`~` is a pretty powerful tool. It's also fast. In particular, think of
`~` rather than a relational operator when you need to match a specific
numeric or string value.

There's also `~~`, the pattern extraction operator, used like this:

```
~~ <subject> <pattern>...
```

The <subject> is matched against <pattern>s; only the portions of
<subject> that match wilcards in <pattern>s are returned as the value of
`~~`. When <subject> is a list, the result is the concatentation of all
<pattern> matches for the first list item, then the second, and so on.

Globbing is handy, but it can't handle the cases where you'd like to
match specific substrings in file and directory names. This is where `xs`
lists come in handy when combined with the concatenation operator, `^`.

This command:

```
ls (foo bar baz qux)^*.abc

```

lists all files having names matching `foo*.abc`, `bar*.abc`, `baz*.abc`
and `qux*.abc`.

Of course, you can combine list concatenation with other forms of
globbing, such as:

```
vi *^(mem wan)^.[ch]
```

You can even concatenate multiple lists; `xs` will generate the cross
product of the lists. This:

```
mv (base config alt)^-^(session client wrapper)^.^(lisp fasl) archive/
```

moves all of the following files from the current directory to the
`archive/` subdirectory:

```
base-session.lisp
base-session.fasl
base-client.lisp
base-client.fasl
base-wrapper.lisp
base-wrapper.fasl
config-session.lisp
config-session.fasl
config-client.lisp
config-client.fasl
config-wrapper.lisp
config-wrapper.fasl
alt-session.lisp
alt-session.fasl
alt-client.lisp
alt-client.fasl
alt-wrapper.lisp
alt-wrapper.fasl
```

In addition to the boolean control-flow operators we've already
encountered, `xs` provides a number of familiar constructs:

```
if <test> <consequent> [else <alternative>]
eval <list>
false
for <list> <command>
result <arg>...
switch <case-and-action>... <default-action>
true
until <test> <body>
while <test> <body><M-`>

exec <command>
exit [<status>]
fork <command>
wait [<pid>]

catch <catcher> <body>
escape <lambda>
forever <command>
map <action> <list>
omap <action> <list>
throw <exception> <arg>...
unwind-protect <body> <cleanup>
```

```
Next:
  - access
  - relops
  - startup
    - login
    - interactive
    - batch
    - other flags
  - extensibility
    - primitives
    - hooks
    - settors
  - pointer to sample code
  - pointer to manual
  - pointer to repo, issue tracker

Manual:
  - add `for` to list of builtins
```
