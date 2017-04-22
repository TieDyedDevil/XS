run 'Character hex escapes' {
    echo \x30 \x7e
}
conds { match '0 ~' }

run 'Character octal escapes' {
    echo \060 \176
}
conds { match '0 ~' }

run 'Character Unicode escapes' {
    echo \u0030 \u007e \U00000030 \U0000007e \u2222 \U00013000
}
conds { match '0 ~ 0 ~ ∢ 𓀀' }

run 'Character invalid escapes' {
    let (n = 0; ec = '\x \x7 \xq \x00 \01 \128 \u \u001 \u123q \u0000 \U \U0000001 \U0001234q \U00000000') {
        for c $ec {
            catch { |e|
                n = `($n + 1)
            } {
                eval 'echo '$c
            }
        }
        $#ec :eq $n && echo yes
    }
}
conds { match yes }
