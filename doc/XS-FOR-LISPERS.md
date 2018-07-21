Canonical `xs` (e.g. the output of %pprint) will have an appearance that
seems familiar to Lisp users. If that's you, here's what you need to know:

- The only `xs` data structure is a list. An `xs` list is always flat;
  never a tree.

- An `xs` word may, with quoting, contain arbitrary characters; not
  necessarily printable. A word is quoted using `''`; a `'` is quoted as
  `''`.

- A limited number of characters may be backslash-escaped. Consult the
  xs(1) man page.

- An arbitrary nonzero byte may be spelled in either hex (`\x##`) or octal
  (`\###`) notation.

- A nonzero UTF-8 byte sequence may be spelled as its hex code point using
  `\u'#...'`.

- `xs` uses two different kinds of brackets whereas Lisp (conventionally)
  uses only one. Use `{}` to bracket code and `()` to bracket data in `xs`.

- An expression within `{}` is called a `program fragment` in `xs`.

- An `xs` function may be `xs` code (primitive or user-defined) or a
  program on $PATH.

- `xs` does not have macros.

- All function arguments are explicitly evaluated (e.g. using `$`, ```,
  ```` or `<=`.

- `xs` control and assignment expressions are shell-like; not Lisp-like.

- An `xs` expression must be on a single logical line. A line may be
  continued with a trailing `\` or by ending the line with an open code
  fragment.

- An `xs` list bracketed by `()` may span multiple lines.

- `xs` does not implement tail recursion.

- `xs` has very limited math capabilities over integer and floating-point
  numbers. Floating-point numbers are stored to only six significant digits.

- An `xs` expression's value may be obtained using `<=`. If the expression
  is an `xs` function, the value is specified by a `result` expression. If
  the expression is a program, the value is the program's return code.

- An `xs` expression's standard output may be obtained using ```
  (backquote). The output is split into words at any character in `$ifs`. As
  a shortcut, ```` (double backquote) binds its first argument to `$ifs`
  during evaluation.

- `xs` provides lexical variables via `let` expressions. Note that the `()`
  are part of the syntax of the expression, and not a list per sé.

- `xs` provides nonlocal control transfer via `catch` and `throw`.

- Signals may be caught. Consult the xs(1) man page.

- `$x(...)` notation may be used to select list elements by their 1-based
  indices. This notation is not available as the target of an assignment
  or as a variable in a math expression.

- `xs` has lambdas and closures. Both downward and upward funargs work,
  with the caveat that an upward funarg *must* be let-bound by its
  returning function.

- `xs` has `%unwind-protect`, which allows one to guarantee execution
  of a cleanup expression.
