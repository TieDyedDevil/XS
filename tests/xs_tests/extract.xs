run 'extract null subject and pattern' {
    v = <={~~ () ()}
}
conds { ~ $#v 0 }

run 'extract null pattern' {
    v = <={~~ word ()}
}
conds { ~ $#v 0 }

run 'extract ? mismatch' {
    v = <={~~ word ?}
}
conds { ~ $#v 0 }

run 'extract ? match' {
    echo -n <={~~ a ?}
}
conds { match-abs a }

run 'extract *' {
    echo -n <={~~ abc *}
}
conds { match-abs abc }

run 'extract [] match' {
    echo -n <={~~ a [ac]}
}
conds { match-abs a }

run 'extract [] mismatch' {
    echo -n <={~~ b [ac]}
}
conds { ~ $#v 0 }

run 'extract multiple ? patterns, no match' {
    v = <={~~ f ?? ???}
}
conds { ~ $#v 0 }

run 'extract multiple ? patterns, match' {
    echo -n <={~~ f ?? ? ???}
}
conds { match-abs f }

run 'extract multiple * patterns, no match' {
    v = <={~~ abcd *x x* *x*}
}
conds { ~ $#v 0 }

run 'extract multiple * patterns, one match, one result' {
    echo -n <={~~ abcd *x x* a* *x*}
}
conds { match-abs bcd }

run 'extract multiple * patterns, one match, mult results' {
    echo -n <={~~ abcd *x x* *c* *x*}
}
conds { match-abs ab d }

run 'extract multiple [] patterns, no match' {
    v = <={~~ abcd abc[xy] ab[xy]d}
}
conds { ~ $#v 0 }

run 'extract multiple [] patterns, one match, one result' {
    echo -n <={~~ abyd abc[xy] ab[xy]d}
}
conds { match-abs y }

run 'extract multiple [] patterns, one match, mult results' {
    echo -n <={~~ abyd a[by]cd a[xb][yc]d}
}
conds { match-abs b y }

run 'extract multiple subjects, no match' {
    v = <={~~ (foo8 bar9 bazzle) *x*}
}
conds { ~ $#v 0 }

run 'extract multiple subjects, one match' {
    echo -n <={~~ (foo8 bar9 bazzle) baz*}
}
conds { match-abs zle }

run 'extract multiple subjects, multiple matches' {
    echo -n <={~~ (foo8 bar9 bazzle) ba*}
}
conds { match-abs r9 zzle }
