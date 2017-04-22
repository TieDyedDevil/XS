run 'Integer :lt comparison' {
    1 :lt 3 && -3 :lt -1 && \
    ! 3 :lt 1 && ! -1 :lt -3 && \
    echo yes
}
conds { match 'yes' }

run 'Integer :le comparison' {
    1 :le 3 && -3 :le -1 && \
    3 :le 3 && -3 :le -3 && \
    ! 3 :le 1 && ! -1 :le -3 && \
    echo yes
}
conds { match 'yes' }

run 'Integer :gt comparison' {
    3 :gt 1 && -1 :gt -3 && \
    ! 1 :gt 3 && ! -3 :gt -1 && \
    echo yes
}
conds { match 'yes' }

run 'Integer :ge comparison' {
    3 :ge 1 && -1 :ge -3 && \
    3 :ge 3 && -3 :ge -3 && \
    ! 1 :ge 3 && ! -3 :ge -1 && \
    echo yes
}
conds { match 'yes' }

run 'Integer :eq comparison' {
    1 :eq 1 && -1 :eq -1 && \
    ! 2 :eq 1 && ! -2 :eq 2 && \
    echo yes
}
conds { match 'yes' }

run 'Integer :ne comparison' {
    2 :ne 1 && -2 :ne -1 && \
    ! 2 :ne 2 && ! -2 :ne -2 && \
    echo yes
}
conds { match 'yes' }

run 'Float :lt comparison' {
    1.0 :lt 3.0 && -3.0 :lt -1.0 && \
    ! 3.0 :lt 1.0 && ! -1.0 :lt -3.0 && \
    echo yes
}
conds { match 'yes' }

run 'Float :le comparison' {
    1.0 :le 3.0 && -3.0 :le -1.0 && \
    3.0 :le 3.0 && -3.0 :le -3.0 && \
    ! 3.0 :le 1.0 && ! -1.0 :le -3.0 && \
    echo yes
}
conds { match 'yes' }

run 'Float :gt comparison' {
    3.0 :gt 1.0 && -1.0 :gt -3.0 && \
    ! 1.0 :gt 3.0 && ! -3.0 :gt -1.0 && \
    echo yes
}
conds { match 'yes' }

run 'Float :ge comparison' {
    3.0 :ge 1.0 && -1.0 :ge -3.0 && \
    3.0 :ge 3.0 && -3.0 :ge -3.0 && \
    ! 1.0 :ge 3.0 && ! -3.0 :ge -1.0 && \
    echo yes
}
conds { match 'yes' }

run 'Float :eq comparison' {
    1.0 :eq 1.0 && -1.0 :eq -1.0 && \
    ! 2.0 :eq 1.0 && ! -2.0 :eq 2.0 && \
    echo yes
}
conds { match 'yes' }

run 'Float :ne comparison' {
    2.0 :ne 1.0 && -2.0 :ne -1.0 && \
    ! 2.0 :ne 2.0 && ! -2.0 :ne -2.0 && \
    echo yes
}
conds { match 'yes' }

run 'Float :lt comparison' {
    1.0 :lt 3.0 && -3.0 :lt -1.0 && \
    ! 3.0 :lt 1.0 && ! -1.0 :lt -3.0 && \
    echo yes
}
conds { match 'yes' }

run 'Integer/Float :le comparison' {
    1 :le 3.0 && -3 :le -1.0 && \
    3 :le 3.0 && -3 :le -3.0 && \
    ! 3 :le 1.0 && ! -1 :le -3.0 && \
    echo yes
}
conds { match 'yes' }

run 'Integer/Float :gt comparison' {
    3 :gt 1.0 && -1 :gt -3.0 && \
    ! 1 :gt 3.0 && ! -3 :gt -1.0 && \
    echo yes
}
conds { match 'yes' }

run 'Integer/Float :ge comparison' {
    3 :ge 1.0 && -1 :ge -3.0 && \
    3 :ge 3.0 && -3 :ge -3.0 && \
    ! 1 :ge 3.0 && ! -3 :ge -1.0 && \
    echo yes
}
conds { match 'yes' }

run 'Integer/Float :eq comparison' {
    1 :eq 1.0 && -1 :eq -1.0 && \
    ! 2 :eq 1.0 && ! -2 :eq 2.0 && \
    echo yes
}
conds { match 'yes' }

run 'Integer/Float :ne comparison' {
    2 :ne 1.0 && -2 :ne -1.0 && \
    ! 2 :ne 2.0 && ! -2 :ne -2.0 && \
    echo yes
}
conds { match 'yes' }

run 'Float/Integer :lt comparison' {
    1.0 :lt 3 && -3.0 :lt -1 && \
    ! 3.0 :lt 1 && ! -1.0 :lt -3 && \
    echo yes
}
conds { match 'yes' }

run 'Float/Integer :le comparison' {
    1.0 :le 3 && -3.0 :le -1 && \
    3.0 :le 3 && -3.0 :le -3 && \
    ! 3.0 :le 1 && ! -1.0 :le -3 && \
    echo yes
}
conds { match 'yes' }

run 'Float/Integer :gt comparison' {
    3.0 :gt 1 && -1.0 :gt -3 && \
    ! 1.0 :gt 3 && ! -3.0 :gt -1 && \
    echo yes
}
conds { match 'yes' }

run 'Float/Integer :ge comparison' {
    3.0 :ge 1 && -1.0 :ge -3 && \
    3.0 :ge 3 && -3.0 :ge -3 && \
    ! 1.0 :ge 3 && ! -3.0 :ge -1 && \
    echo yes
}
conds { match 'yes' }

run 'Float/Integer :eq comparison' {
    1.0 :eq 1 && -1.0 :eq -1 && \
    ! 2.0 :eq 1 && ! -2.0 :eq 2 && \
    echo yes
}
conds { match 'yes' }

run 'Float/Integer :ne comparison' {
    2.0 :ne 1 && -2.0 :ne -1 && \
    ! 2.0 :ne 2 && ! -2.0 :ne -2 && \
    echo yes
}
conds { match 'yes' }

run 'String :lt comparison' {
    a :lt b && a :lt aa && a :lt ab && \
    ! b :lt a && ! aa :lt a && ! ab :lt a && \
    echo yes
}
conds { match 'yes' }

run 'String :le comparison' {
    a :le b && a :le aa && a :le ab && \
    a :le a && \
    ! b :le a && ! aa :le a && ! ab :le a && \
    echo yes
}
conds { match 'yes' }

run 'String :gt comparison' {
    b :gt a && bb :gt b && ba :gt b && \
    ! a :gt b && ! b :gt bb && ! b :gt ba && \
    echo yes
}
conds { match 'yes' }

run 'String :ge comparison' {
    b :ge a && bb :ge b && ba :ge b && \
    b :ge b && \
    ! a :ge b && ! b :ge bb && ! b :ge bb && \
    echo yes
}
conds { match 'yes' }

run 'String :eq comparison' {
    a :eq a && aa :eq aa && \
    ! b :eq a && \
    echo yes
}
conds { match 'yes' }

run 'String :ne comparison' {
    a :ne b && ! a :ne a &&
    echo yes
}
conds { match 'yes' }
