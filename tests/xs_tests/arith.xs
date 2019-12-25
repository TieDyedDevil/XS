run 'Simple addition' {
    echo `(1 + 2)
}
conds { match '3' }

run 'Simple multiplication' {
    echo `(1 * 2)
}
conds { match '2' }

run 'Simple division' {
    echo `(4 / 2)
}
conds { match '2' }

run 'Simple modulus' {
    echo `(5 % 3)
}
conds { match '2' }

run 'Simple subtraction' {
    echo `(2 - 1)
}
conds { match '1' }

run 'Simple exponentiation' {
    echo `(3 ** 4)
}
conds { match '81' }

run 'Order of operations' {
    echo `(4 * 3 + 2 * 1 + 3 / 2 - 4)
}
conds { match '11' }

run 'Floating point operation' {
    echo `(3.5 - 1.5 * 2)
}
conds { match '0.5' }

run 'Check invalid integer constant' {
    echo `(3000000000)
}
conds { match 'Could not handle' }

run 'Check invalid floating-point constant' {
    echo `(1..01)
}
conds { match 'Could not handle' }
