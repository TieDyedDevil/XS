run 'printf %o negative' {
    printf '%o' -32
}
conds { match 37777777740 }

run 'printf %u negative' {
    printf '%u' -32
}
conds { match 4294967264 }

run 'printf %x negative' {
    printf '%x' -32
}
conds { match ffffffe0 }

run 'printf %X negative' {
    printf '%X' -32
}
conds { match FFFFFFE0 }

run 'printf %a' {
    printf '%a %a' 3.14 -2.718
}
conds { match 0x1.91eb851eb851fp+1 -0x1.5be76c8b43958p+1 }

run 'printf %a w/ integral numeric arg' {
    printf '%a %a' 73 -32
}
conds { match 0x1.24p+6 -0x1p+5 }

run 'printf %A' {
    printf '%A %A' 3.14 -2.718
}
conds { match 0X1.91EB851EB851FP+1 -0X1.5BE76C8B43958P+1 }

run 'printf %A w/ integral numeric arg' {
    printf '%A %A' 73 -32
}
conds { match 0X1.24P+6 -0X1P+5 }
