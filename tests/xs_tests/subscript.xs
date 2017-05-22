run 'Subscript one valid index' {
    let (l = a b c d e f g h i j) {
        echo $l(3)
    }
}
conds { match 'c' }

run 'Subscript one zero index' {
    let (l = a b c d e f g h i j) {
        echo $l(0)
    }
}
conds { expect-failure }    

run 'Subscript one negative index' {
    let (l = a b c d e f g h i j) {
        echo $l(-1)
    }
}
conds { expect-failure }    

run 'Subscript index past end' {
    let (l = a b c d e f g h i j) {
        echo $l(11)
    }
}
conds { match () }

run 'Subscript one definite range' {
    let (l = a b c d e f g h i j) {
        echo $l(4 ... 6)
    }
}
conds { match d e f }

run 'Subscript one open beginning range' {
    let (l = a b c d e f g h i j) {
        echo $l(... 6)
    }
}
conds { match a b c d e f }

run 'Subscript one open ending range' {
    let (l = a b c d e f g h i j) {
        echo $l(7 ...)
    }
}
conds { match g h i j }

run 'Subscript one reversed definite range' {
    let (l = a b c d e f g h i j) {
        echo $l(6 ... 4)
    }
}
conds { match f e d }

run 'Subscript mixed' {
    let (l = a b c d e f g h i j) {
        echo $l(6 ... 4 8 ... 9 11 2 ... 1 11 5)
    }
}
conds { match f e d h i b a e }

run 'Subscript one range bad start' {
    let (l = a b c d e f g h i j) {
        echo $l(-1 ... 6)
    }
}
conds { expect-failure }

run 'Subscript one range bad end' {
    let (l = a b c d e f g h i j) {
        echo $l(4 ... -1)
    }
}
conds { expect-failure }

run 'Subscript missing index' {
    let (l = a b c d e f g h i j) {
        echo $l()
    }
}
conds { match () }
