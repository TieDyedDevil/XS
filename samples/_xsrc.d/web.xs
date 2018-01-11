fn web {|*|
	.d 'Open web URL'
	.a '[-t] [URL]'
	.c 'web'
	if {{!~ $DISPLAY ()} && {~ $*(1) -t}} {
		local (DISPLAY) {web $*(2 ...)}
	} else {
		web-browser $*
	}
}

## Sites
fn guardian {
	.d 'The Guardian'
	.c 'web'
	web https://www.theguardian.com/us
}
fn jos {
	.d 'Joel On Software'
	.c 'web'
	web https://www.joelonsoftware.com/
}
fn lwn {
	.d 'Linux Weekly News'
	.c 'web'
	web -t https://lwn.net/
}

## Web lookups
fn amazon {|*|
	.d 'Search Amazon'
	.a '[QUERY]'
	.c 'web'
	.r 'dictionary github google scholar thesaurus wikipedia youtube'
	.web-query https://amazon.com/ s/\?field-keywords= $*
}
fn dictionary {|*|
	.d 'Search Dictonary'
	.a '[QUERY]'
	.c 'web'
	.r 'amazon github google scholar thesaurus wikipedia youtube'
	.web-query http://dictionary.com/ search\?q= $*
}
fn github {|*|
	.d 'Search GitHub'
	.a '[QUERY]'
	.c 'web'
	.r 'amazon dictionary google scholar thesaurus wikipedia youtube'
	.web-query https://github.com/ search\?q= $*
}
fn google {|*|
	.d 'Search Google'
	.a '[QUERY]'
	.c 'web'
	.r 'amazon dictionary github scholar thesaurus wikipedia youtube'
	.web-query https://google.com/ search\?q= $*
}
fn scholar {|*|
	.d 'Search Google Scholar'
	.a '[QUERY]'
	.c 'web'
	.r 'amazon dictionary github google thesaurus wikipedia youtube'
	.web-query https://scholar.google.com/ scholar\?hl=en\&q= $*
}
fn thesaurus {|*|
	.d 'Search Thesaurus'
	.a '[QUERY]'
	.c 'web'
	.r 'amazon dictionary github google scholar wikipedia youtube'
	.web-query http://thesaurus.com/ search\?q= $*
}
fn wikipedia {|*|
	.d 'Search Wikipedia'
	.a '[QUERY]'
	.c 'web'
	.r 'amazon dictionary github google scholar thesaurus youtube'
	.web-query https://en.wikipedia.org/ wiki/Special:Search\?search= $*
}
fn youtube {|*|
	.d 'Search YouTube'
	.a '[QUERY]'
	.c 'web'
	.r 'amazon dictionary github google scholar thesaurus wikipedia'
	.web-query https://youtube.com/ results\?search_query= $*
}
