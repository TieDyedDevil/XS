# index of prompt, prompt attribute, sequence attribute

%aset pr cinit 16 bold underline # vt  default
%aset pr pinit 27 bold underline # pty default

%aset pr 1 \u252c \u251c
#    1┬
#    1├
#    2┬
%aset pr 2 \u253c \u251c
#    1┼
#    1├
#    2┼
%aset pr 3 \u256a \u251c
#    1╪
#    1├
#    2╪
%aset pr 4 \u250c \u251c
#    1┌
#    1├
#    2┌
%aset pr 5 \u2510 \u251c
#    1┐
#    1├
#    2┐
%aset pr 6 \u00bb \u203a
#    1»
#    1›
#    2»
%aset pr 7 \u0394 \u00a6
#    1Δ
#    1¦
#    2Δ
%aset pr 8 \u041f \u045f
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
%aset pr 11 \u25c6 \u2191
#    1◆
#    1↑
#    2◆
%aset pr 12 \u2500 \u256c
#    1─
#    1╬
#    2─
%aset pr 13 \u03b1 \u03b2
#    1α
#    1β
#    1α
%aset pr 14 \u00b9 \u00b2
#    1¹
#    1²
#    1¹
%aset pr 15 \; \ 
#    1;
#    1 
#    2;
%aset pr 16 \u03bb \u2026
#    1λ
#    1…
#    2λ
%aset pr 17 \u03c8 \u03c6
#    1ψ
#    1φ
#    2ψ
%aset pr 18 \u00a4 \u2022
#    1¤
#    1•
#    2¤
%aset pr 19 \u00b6 \u00a7
#    1¶
#    1§
#    2¶
%aset pr 20 \u03c1 \u03c4
#    1ρ
#    1τ
#    1ρ
%aset pr 21 \u2020 \u2021
#    1†
#    1‡
#    2†
%aset pr 22 \u0192 \u2310
#    1ƒ
#    1⌐
#    2ƒ
%aset pr 23 \u039b \u039e
#    1Λ
#    1Ξ
#    2Λ
%aset pr 24 \u013f \u0141
#    1Ŀ
#    1Ł
#    2Ŀ

# Mark the largest index that'll work in the console.
%aset pr cmax 24

## The following won't render in the console.

%aset pr 25 \u2b95 \u2b8a
#    1⮕
#    2⮊
#    1⮕
%aset pr 26 \u2b72 \u2b71
#    1⭲
#    2⭱
#    1⭲
%aset pr 27 \u2b62 \u2b77
#    1⭢
#    2⭷
#    1⭢
%aset pr 28 \u2bee \u2bed
#    1⯮
#    2⯭
#    1⯮

# Mark the largest index that'll work in a pty.
%aset pr pmax 28
