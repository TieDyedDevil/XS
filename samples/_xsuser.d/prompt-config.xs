# index of prompt, prompt attribute, sequence attribute

%aset pr cinit 16 bold underline # vt  default
%aset pr pinit 27 bold underline # pty default

%aset pr 1 \u'252c' \u'251c'
#    1┬
#    1├
#    2┬
%aset pr 2 \u'253c' \u'251c'
#    1┼
#    1├
#    2┼
%aset pr 3 \u'256a' \u'251c'
#    1╪
#    1├
#    2╪
%aset pr 4 \u'250c' \u'251c'
#    1┌
#    1├
#    2┌
%aset pr 5 \u'2510' \u'251c'
#    1┐
#    1├
#    2┐
%aset pr 6 \u'00bb' \u'203a'
#    1»
#    1›
#    2»
%aset pr 7 \u'0394' \u'00a6'
#    1Δ
#    1¦
#    2Δ
%aset pr 8 \u'041f' \u'045f'
#    1П
#    1џ
#    2П
%aset pr 9 \) \(
#    1)
#    1(
#    1)
%aset pr 10 \> \<
#    1>
#    1<
#    2>
%aset pr 11 \u'25c6' \u'2191'
#    1◆
#    1↑
#    2◆
%aset pr 12 \u'2500' \u'256c'
#    1─
#    1╬
#    2─
%aset pr 13 \u'03b1' \u'03b2'
#    1α
#    1β
#    1α
%aset pr 14 \u'00b9' \u'00b2'
#    1¹
#    1²
#    1¹
%aset pr 15 \; \ 
#    1;
#    1 
#    2;
%aset pr 16 \u'03bb' \u'2026'
#    1λ
#    1…
#    2λ
%aset pr 17 \u'03c8' \u'03c6'
#    1ψ
#    1φ
#    2ψ
%aset pr 18 \u'00a4' \u'2022'
#    1¤
#    1•
#    2¤
%aset pr 19 \u'00b6' \u'00a7'
#    1¶
#    1§
#    2¶
%aset pr 20 \u'03c1' \u'03c4'
#    1ρ
#    1τ
#    1ρ
%aset pr 21 \u'2020' \u'2021'
#    1†
#    1‡
#    2†
%aset pr 22 \u'0192' \u'2310'
#    1ƒ
#    1⌐
#    2ƒ
%aset pr 23 \u'039b' \u'039e'
#    1Λ
#    1Ξ
#    2Λ
%aset pr 24 \u'013f' \u'0141'
#    1Ŀ
#    1Ł
#    2Ŀ

# Mark the largest index that'll work in the console.
%aset pr cmax 24

## The following won't render in the console.

%aset pr 25 \u'2b95' \u'2b8a'
#    1⮕
#    2⮊
#    1⮕
%aset pr 26 \u'2b72' \u'2b71'
#    1⭲
#    2⭱
#    1⭲
%aset pr 27 \u'2b62' \u'2b77'
#    1⭢
#    2⭷
#    1⭢
%aset pr 28 \u'2bee' \u'2bed'
#    1⯮
#    2⯭
#    1⯮
%aset pr 29 \u'012460' \u'012462'
#    1𒑠
#    2𒑢
#    1𒑠
%aset pr 30 \u'27e3' \u'27e1'
#    1⟣
#    2⟡
#    1⟣
%aset pr 31 \u'01f7c1' \u'01f7c3'
#    1🟁
#    2🟃
#    1🟁
%aset pr 32 \u'01f7c5' \u'01f7c7'
#    1🟅
#    2🟇
#    1🟅
%aset pr 33 \u'01d032' \u'01d04c'
#    1𝀲
#    2𝁌
#    1𝀲
%aset pr 34 \u'01f5e8' \u'01f5ea'
#    1🗨
#    2🗪
#    1🗨
%aset pr 35 \u'2058' \u'2059'
#    1⁘
#    2⁙
#    1⁘
%aset pr 36 \u'2a15' \u'2a16'
#    1⨕
#    2⨖
#    1⨕
%aset pr 37 \u'2994' \u'2995'
#    1⦔
#    2⦕
#    1⦔
%aset pr 38 \u'2032' \u'2033'
#    1′
#    2″
#    1′

# Mark the largest index that'll work in a pty.
%aset pr pmax 38
