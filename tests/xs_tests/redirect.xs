run 'Bad command output redirection' {
	echo >{/dev/null}
}
conds { match '/dev/null: Permission denied' }

run 'Bad command input redirection' {
	echo <{/dev/null}
}
conds { match '/dev/null: Permission denied' }
