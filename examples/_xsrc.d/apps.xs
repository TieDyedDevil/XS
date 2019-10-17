# Applications in /usr/share/applications having dotted names.

fn pulseeffects {|*|
	.d 'PulseAudio effects'
	.a '[pulseeffects_OPTIONS]'
	.c 'alias'
	result %with-terminal
	/usr/bin/pulseeffects $*
}

fn krita {|*|
	.d 'Sketching and painting'
	.a '[krita_OPTIONS]'
	.c 'alias'
	result %with-terminal
	/usr/bin/krita $*
}

fn zathura {|*|
	.d 'Document viewer'
	.a '[zathura_OPTIONS]'
	.c 'alias'
	result %with-terminal
	/usr/bin/zathura $*
}

fn qgis {
	.d 'QGIS Geographic Information System'
	.a '[qgis_OPTIONS]'
	.c 'alias'
	result %with-terminal
	/usr/bin/qgis $*
}

fn gnome-font-viewer {|*|
	.d 'GNOME font viewer'
	.a '[gnome-font-viewer_OPTIONS]'
	.c 'alias'
	result %with-terminal
	/usr/bin/gnome-font-viewer $*
}

fn xload {|*|
	.d 'Graphical load average'
	.a '[xload_OPTIONS]'
	.c 'alias'
	result %with-terminal
	/usr/bin/xload $*
}

fn xbiff {|*|
	.d 'Graphical email notifier'
	.a '[xbiff_OPTIONS]'
	.c 'alias'
	result %with-terminal
	/usr/bin/xbiff $*
}

fn oobase {|*|
	.d 'OpenOffice base'
	.a '[oobase_OPTIONS]'
	.c 'alias'
	result %with-terminal
	/usr/bin/oobase $*
}

fn oocalc {|*|
	.d 'OpenOffice spreadsheet'
	.a '[oocalc_OPTIONS]'
	.c 'alias'
	result %with-terminal
	/usr/bin/oocalc $*
}

fn oodraw {|*|
	.d 'OpenOffice draw'
	.a '[oodraw_OPTIONS]'
	.c 'alias'
	result %with-terminal
	/usr/bin/oodraw $*
}

fn ooffice {|*|
	.d 'OpenOffice'
	.a '[ooffice_OPTIONS]'
	.c 'alias'
	result %with-terminal
	/usr/bin/ooffice $*
}

fn ooimpress {|*|
	.d 'OpenOffice presentation'
	.a '[ooimpress_OPTIONS]'
	.c 'alias'
	result %with-terminal
	/usr/bin/ooimpress $*
}

fn oomath {|*|
	.d 'OpenOffice math'
	.a '[oomath_OPTIONS]'
	.c 'alias'
	result %with-terminal
	/usr/bin/oomath $*
}

fn ooviewdoc {|*|
	.d 'OpenOffice document viewer'
	.a '[ooviewdoc_OPTIONS]'
	.c 'alias'
	result %with-terminal
	/usr/bin/ooviewdoc $*
}

fn oowriter {|*|
	.d 'OpenOffice writer'
	.a '[oowriter_OPTIONS]'
	.c 'alias'
	result %with-terminal
	/usr/bin/oowriter $*
}

fn recoll {|*|
	.d 'Full-text search'
	.a '[QUERY]'
	.c 'alias'
	result %with-terminal
	if {~ $* ()} {
		/usr/bin/recoll
	} else {
		/usr/bin/recoll -q $*
	}
}
