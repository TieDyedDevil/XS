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

Looking at the from the inside out, we're constructing a word like
`\uNNNN`. This is how `xs` names a Unicode code point. The value of
`$cp` is lambda-bound; that's the `|cp|` notation in the inner program
fragment. `eval` expects a string, but `\uNNNN` is a word. `echo` does
what it always does: it prints a string. `eval` parses and evaluates the
given text, producing the `ǝ` as a word. Now look at the two program
fragments. The inner fragment, the lambda expression, is in the command
position; `01dd` is its argument, which gets bound to `cp` in the lambda
list. The backquote says "run this command." Finally, the leftmost `echo`
prints the `ǝ` character.
