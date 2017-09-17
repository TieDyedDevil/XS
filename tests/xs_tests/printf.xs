run 'printf %s' {
    printf %s foo
}
conds { match foo }

run 'printf %s w/ width' {
    printf %8s foo
}
conds { match '     foo' }

run 'printf %s w/ left' {
    printf %-8s foo
}
conds { match 'foo     ' }

run 'printf %s w/ precision' {
    printf %.3s foobar
}
conds { match foo }

run 'printf %c' {
    printf %c%c a 1
}
conds { match a1 }

run 'printf %c w/ non-char arg' {
    printf %c ab
}
conds { match character value required }

run 'printf %d' {
    printf '%d %d' 73 -32
}
conds { match 73 -32 }

run 'printf %d w/ non-integral numeric arg' {
    printf %d 3.14
}
conds { match integral value required }

run 'printf %d w/ non-numeric arg' {
    printf %d foo
}
conds { match numeric value required }

run 'printf %i' {
    printf '%i %i' 73 -32
}
conds { match 73 -32 }

run 'printf %i w/ non-integral numeric arg' {
    printf %i 3.14
}
conds { match integral value required }

run 'printf %i w/ non-numeric arg' {
    printf %i foo
}
conds { match numeric value required }

run 'printf %o' {
    printf '%o' 73
}
conds { match 111 }

run 'printf %o w/ non-integral numeric arg' {
    printf %o 3.14
}
conds { match integral value required }

run 'printf %o w/ non-numeric arg' {
    printf %o foo
}
conds { match numeric value required }

run 'printf %u' {
    printf '%u' 73
}
conds { match 73 }

run 'printf %u w/ non-integral numeric arg' {
    printf %u 3.14
}
conds { match integral value required }

run 'printf %u w/ non-numeric arg' {
    printf %u foo
}
conds { match numeric value required }

run 'printf %x' {
    printf '%x' 73
}
conds { match 49 }

run 'printf %x w/ non-integral numeric arg' {
    printf %x 3.14
}
conds { match integral value required }

run 'printf %x w/ non-numeric arg' {
    printf %x foo
}
conds { match numeric value required }

run 'printf %X' {
    printf '%X' 73
}
conds { match 49 }

run 'printf %X w/ non-integral numeric arg' {
    printf %X 3.14
}
conds { match integral value required }

run 'printf %X w/ non-numeric arg' {
    printf %X foo
}
conds { match numeric value required }

run 'printf %f' {
    printf '%f %f' 3.14 -2.718
}
conds { match 3.140000 -2.718000 }

run 'printf %f w/ integral numeric arg' {
    printf '%f %f' 73 -32
}
conds { match 73.000000 -32.000000 }

run 'printf %f w/ non-numeric arg' {
    printf %f foo
}
conds { match numeric value required }

run 'printf %e' {
    printf '%e %e' 3.14 -2.718
}
conds { match 3.140000e+00 -2.718000e+00 }

run 'printf %e w/ integral numeric arg' {
    printf '%e %e' 73 -32
}
conds { match 7.300000e+01 -3.200000e+01 }

run 'printf %e w/ non-numeric arg' {
    printf %e foo
}
conds { match numeric value required }

run 'printf %E' {
    printf '%E %E' 3.14 -2.718
}
conds { match 3.140000E+00 -2.718000E+00 }

run 'printf %E w/ integral numeric arg' {
    printf '%E %E' 73 -32
}
conds { match 7.300000E+01 -3.200000E+01 }

run 'printf %E w/ non-numeric arg' {
    printf %E foo
}
conds { match numeric value required }

run 'printf %g' {
    printf '%g %g %g %g' 3.14 -2.718 0.0001 0.00001
}
conds { match 3.14 -2.718 0.0001 1e-05 }

run 'printf %g w/ integral numeric arg' {
    printf '%g %g %g %g' 73 -32 100000 1000000
}
conds { match 73 -32 100000 1e+06 }

run 'printf %g w/ non-numeric arg' {
    printf %g foo
}
conds { match numeric value required }

run 'printf %G' {
    printf '%G %G %G %G' 3.14 -2.718 0.0001 0.00001
}
conds { match 3.14 -2.718 0.0001 1E-05 }

run 'printf %G w/ integral numeric arg' {
    printf '%G %G %G %G' 73 -32 100000 1000000
}
conds { match 73 -32 100000 1E+06 }

run 'printf %g w/ non-numeric arg' {
    printf %g foo
}
conds { match numeric value required }

run 'printf %a w/ non-numeric arg' {
    printf %a foo
}
conds { match numeric value required }

run 'printf %a w/ non-numeric arg' {
    printf %a foo
}
conds { match numeric value required }

run 'printf %%' {
    printf x%%%%y
}
conds { match x%%y }

run 'printf w/ excess formats' {
    printf %d%s%f 8 hello
}
conds { match more fmts than args }

run 'printf w/ excess arguments' {
    printf %d%s%f 8 hello 57.9 x
}
conds { match more args than fmts }
