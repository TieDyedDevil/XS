fn web {|*|
	.d 'Open web URL'
	.a '[URL]  # graphical browser'
	.a '-t [URL]  # text browser'
	.a '-i [URL]  # incognito graphical browser'
	.c 'web'
	if {{!~ $DISPLAY ()} && {~ $*(1) -t}} {
		local (DISPLAY) {web $*(2 ...)}
	} else {
		web-browser $*
	}
}

## News Sites

fn aljazeera-news {
	.d 'Aljazeera'
	.c 'web'
	web https://www.aljazeera.com/
}

fn allsides-news {
	.d 'AllSides'
	.c 'web'
	web https://www.allsides.com/
}

fn bbc-world-news {
	.d 'BBC News'
	.c 'web'
	web https://www.bbc.com/news
}

fn cnn-news {
	.d 'CNN News'
	.c 'web'
	web https://www.cnn.com/
}

fn current-affairs {
	.d 'Current Affairs'
	.c 'web'
	web https://www.currentaffairs.org/
}

fn lwn {
	.d 'Linux Weekly News'
	.c 'web'
	web -t https://lwn.net/
}

fn newworldwar {
	.d 'New World War'
	.c 'web'
	web http://newworldwar.org/
}

fn phoronix {
	.d 'Linux hardware news'
	.c 'web'
	web https://www.phoronix.com/
}

fn politico-news {
	.d 'Politico'
	.c 'web'
	web https://www.politico.com/
}

fn reuters-news {
	.d 'Reuters'
	.c 'web'
	web https://www.reuters.com/
}

fn the-guardian-news {
	.d 'The Guardian'
	.c 'web'
	web https://www.theguardian.com/us
}

fn the-hill-news {
	.d 'The Hill'
	.c 'web'
	web https://thehill.com/
}

## Web lookups

fn amazon {|*|
	.d 'Search Amazon'
	.a '[QUERY]'
	.c 'web'
	.r 'github google maps scholar searx wikipedia youtube'
	.web-query https://amazon.com/ s/\?field-keywords= $*
}

fn github {|*|
	.d 'Search GitHub'
	.a '[QUERY]'
	.c 'web'
	.r 'amazon google maps scholar searx wikipedia youtube'
	.web-query https://github.com/ search\?q= $*
}

fn githubstatus {
	.d 'Visit GitHub service status page'
	.c 'web'
	.r 'github'
	web https://githubstatus.com/
}

fn google {|*|
	.d 'Search Google'
	.a '[QUERY]'
	.c 'web'
	.r 'amazon github maps scholar searx wikipedia youtube'
	.web-query https://google.com/ search\?q= $*
}

fn lyrics {|*|
	.d 'Search song lyrics'
	.a '[QUERY]'
	.c 'web'
	.web-query https://search.azlyrics.com/ search.php\?q= $*
}

fn maps {|*|
	.d 'Search Google Maps'
	.a '[QUERY]'
	.c 'web'
	.r 'amazon github google scholar searx wikipedia youtube'
	.web-query https://maps.google.com/ \?q= $*
}

fn scholar {|*|
	.d 'Search Google Scholar'
	.a '[QUERY]'
	.c 'web'
	.r 'amazon github google maps searx wikipedia youtube'
	.web-query https://scholar.google.com/ scholar\?hl=en\&q= $*
}

fn searx {|*|
	.d 'Search searx instance (private metasearch)'
	.a '[QUERY]'
	.c 'web'
	.r 'amazon github google maps scholar wikipedia youtube'
	.web-query https://searx.info/ \?q= $*
}

fn wikipedia {|*|
	.d 'Search Wikipedia'
	.a '[QUERY]'
	.c 'web'
	.r 'amazon github google maps scholar searx youtube'
	.web-query https://en.wikipedia.org/ wiki/Special:Search\?search= $*
}

fn youtube {|*|
	.d 'Search YouTube'
	.a '[QUERY]'
	.c 'web'
	.r 'amazon github google maps scholar searx wikipedia'
	.web-query https://youtube.com/ results\?search_query= $*
}

## Special

fn weather {|*|
	.d 'Show weather and forecast.'
	.a '[LOCATION]'
	.a '-l  # attempt to locate'
	.a '(none)  # use default location or attempt to locate'
	.c 'web'
	let (loc = <={%flatten + $*}; n = ''; r; d = 1; \
	cf = ~/.config/weather.default; dl = 'Oymyakon, Russia') {
		if {~ $* -l} {
			loc = ''
		} else {
			access -f $cf && loc = `` \n {cat $cf}
		}
		`{tput cols} :lt 126 && n = n
		r = `{tput lines}
		$r :ge 30 && $r :lt 40 && d = 2
		$r :ge 40 && d = 3
		%with-tempfile tf {
			curl -Ss wttr.in/$loc\?$d^q$n|head -n-2 >$tf
			if {grep -c $dl $tf >/dev/null && access -f $cf \
						&& !~ `` \n {cat $cf} $dl} {
				echo 'DEFAULT LOCATION'
				weather `{cat $cf}
			} else {
				%with-terminal weather {cat $tf|%wt-pager}
			}
		}
	}
}

# Filter inquiry
fn isblocked {|*|
	.d 'Query web block list'
	.a 'NAME'
	.c 'web'
	%with-terminal isblocked {
		if {~ $* ()} {.usage isblocked} \
		else grep -iF $* <{awk '
BEGIN {pass=0}
/Biased\/Misleading\/Manipulative/ {pass=1}
/^#/ {}
/^$/ {}
{if (pass) print}
' /etc/privoxy/user.action} | %wt-pager
	}
}
