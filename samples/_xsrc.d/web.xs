fn web {|*|
	.d 'Open web URL'
	.c 'web'
	.a 'URL'
	let (error = false) {
		switch $#* (
		0 web-browser
		1 {web-browser $*}
		{throw error web 'spaces not allowed in URL'}
		)
	}
}

## Web lookups
fn .web-query {|site path query|
	if {~ $#query 0} {
		web-browser $site
	} else {
		let (q) {
			q = `{echo $^query|sed 's/\+/%2B/g'|tr ' ' +}
			web-browser $site^$path^$q
		}
	}
}
fn amazon {|*|
	.d 'Search Amazon'
	.c 'web'
	.a '[QUERY]'
	.web-query https://amazon.com/ s/\?field-keywords= $*
}
fn google {|*|
	.d 'Search Google'
	.c 'web'
	.a '[QUERY]'
	.web-query https://google.com/ search\?q= $*
}
fn guardian {
	.d 'The Guardian'
	.c 'web'
	web https://www.theguardian.com/us
}
fn scholar {|*|
	.d 'Search Google Scholar'
	.c 'web'
	.a '[QUERY]'
	.web-query https://scholar.google.com/ scholar\?hl=en\&q= $*
}
fn wikipedia {|*|
	.d 'Search Wikipedia'
	.c 'web'
	.a '[QUERY]'
	.web-query https://en.wikipedia.org/ wiki/Special:Search\?search= $*
}
fn youtube {|*|
	.d 'Search YouTube'
	.c 'web'
	.a '[QUERY]'
	.web-query https://youtube.com/ results\?search_query= $*
}
