run 'extract null subject and pattern' {
    echo -n <={%count <={~~ () ()}}
}
conds { match-abs 0 }

run 'extract null pattern' {
    echo -n <={%count <={~~ word ()}}
}
conds { match-abs 0 }

run 'extract ? mismatch' {
    echo -n <={%count <={~~ word ?}}
}
conds { match-abs 0 }

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
    echo -n <={%count <={~~ b [ac]}}
}
conds { match-abs 0 }

run 'extract multiple ? patterns, no match' {
    echo -n <={%count <={~~ f ?? ???}}
}
conds { match-abs 0 }

run 'extract multiple ? patterns, match' {
    echo -n <={~~ f ?? ? ???}
}
conds { match-abs f }

run 'extract multiple * patterns, no match' {
    echo -n <={%count <={~~ abcd *x x* *x*}}
}
conds { match-abs 0 }

run 'extract multiple * patterns, one match, one result' {
    echo -n <={~~ abcd *x x* a* *x*}
}
conds { match-abs bcd }

run 'extract multiple * patterns, one match, mult results' {
    echo -n <={~~ abcd *x x* *c* *x*}
}
conds { match-abs ab d }

run 'extract multiple [] patterns, no match' {
    echo -n <={%count <={~~ abcd abc[xy] ab[xy]d}}
}
conds { match-abs 0 }

run 'extract multiple [] patterns, one match, one result' {
    echo -n <={~~ abyd abc[xy] ab[xy]d}
}
conds { match-abs y }

run 'extract multiple [] patterns, one match, mult results' {
    echo -n <={~~ abyd a[by]cd a[xb][yc]d}
}
conds { match-abs b y }

run 'extract multiple subjects, no match' {
    echo -n <={%count <={~~ (foo8 bar9 bazzle) *x*}}
}
conds { match-abs 0 }

run 'extract multiple subjects, one match' {
    echo -n <={~~ (foo8 bar9 bazzle) baz*}
}
conds { match-abs zle }

run 'extract multiple subjects, multiple matches' {
    echo -n <={~~ (foo8 bar9 bazzle) ba*}
}
conds { match-abs r9 zzle }
