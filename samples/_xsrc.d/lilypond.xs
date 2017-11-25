fn lilypond-help {
	.d 'LilyPond documentation'
	.c 'help'
	.r 'lilypond-pdfs'
	web /usr/share/doc/lilypond-doc/share/doc/lilypond/html/index.html
}
fn lilypond-pdfs {
	.d 'View Lilypond PDF documentation'
	.c 'help'
	.r 'lilypond-help'
	let (docs = `{ls /usr/share/doc/lilypond-doc/share/doc/lilypond/^ \
			html/Documentation/*.pdf|grep -v '\...\.pdf$'}; \
		items; desc; action; i = 1; \
		n = (a b c d e f g h i j k l m n o p q r s t u v w x y z)) {
		for f $docs {
			desc = `{basename $f .pdf}
			action = `` '' {printf '{zathura %s}' $f}
			items = $items $n($i) $desc $action
			i = `($i+1)
		}
		%menu 'Lilypond docs (^D to end)' $items
	}
}
