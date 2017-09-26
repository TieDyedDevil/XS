run 'match null subject and pattern' {
    echo -n <={~ () ()}
}
conds { match-abs 0 }

run 'match non-null subject and null pattern' {
    echo -n <={~ foo ()}
}
conds { match-abs 1 }

run 'match null subject and non-null pattern' {
    echo -n <={~ () foo}
}
conds { match-abs 1 }

run 'match single subject and multiple patterns, one match' {
    echo -n <={~ bazzle foo* bar* baz* *xy}
}
conds { match-abs 0 }

run 'match single subject and multiple patterns, no match' {
    echo -n <={~ bazzle foo* bor* bag* *xy}
}
conds { match-abs 1 }

run 'match multiple subjects and single pattern, match' {
    echo -n <={~ (blop blip blep) *le[ap]}
}
conds { match-abs 0 }

run 'match multiple subjects and single pattern, no match' {
    echo -n <={~ (blop blip blep) *le[ad]}
}
conds { match-abs 1 }

run 'match multiple subjects and single pattern, one match' {
    echo -n <={~ (blop blip blep) *le[ap]}
}
conds { match-abs 0 }

run 'match multiple subjects and single pattern, multiple matches' {
    echo -n <={~ (blop blip blep) bl[oe]?}
}
conds { match-abs 0 }

run 'match multiple subjects and patterns, no match' {
    echo -n <={~ (blop blip blep) *lo?? ?le[ap]?}
}
conds { match-abs 1 }

run 'match multiple subjects and patterns, one match' {
    echo -n <={~ (blop blip blep) *lo?? ?le[ap]}
}
conds { match-abs 0 }

run 'match multiple subjects and patterns, multiple matches' {
    echo -n <={~ (blop blip blep) *lo? ?le[ap]}
}
conds { match-abs 0 }
