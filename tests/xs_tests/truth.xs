run 'Truth: 0' {
    result 0 && echo yes
}
conds { match 'yes' }

run 'Truth: ''''' {
    result '' && echo yes
}
conds { match 'yes' }

run 'Truth: ()' {
    result '' && echo yes
}
conds { match 'yes' }

run 'Truth: 1' {
    result 1 || echo no
}
conds { match 'no' }

run 'Truth: ''x''' {
    result 'x' || echo no
}
conds { match 'no' }

run 'Truth: 0.0' {
    result 0.0 || echo no
}
conds { match 'no' }

run 'Truth: (0 0 0 0)' {
    result (0 0 0 0) && echo yes
}
conds { match 'yes' }

run 'Truth: (0 0 1 0)' {
    result (0 0 1 0) || echo no
}
conds { match 'no' }
