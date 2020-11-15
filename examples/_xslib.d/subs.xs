fn .usage {|*|
	# Display args help for named function.
	if {{~ $#* 1} && {!~ $* -*}} {help $*|awk -f <{cat <<'EOF'
/^a: / {pass=1;}
/^[^a]: / {pass=0;}
{if (pass) {print}}
EOF
		}
	}
}

fn .pu {|*|
	# User ps: [FLAGS] [USER]
	let (flags) {
		while {~ $*(1) -*} {
			~ $*(1) -[fFcyM] && flags = $flags $*(1)
			* = $(2 ...)
		}
		ps -Hlj $flags -U^`{if {~ $#* 0} {echo $USER} else {echo $*}}
	}
}

fn .d {|*|
	# Help tag: docstring

}
fn .a {|*|
	# Help tag: argstring
}

fn .c {|*|
	# Help tag: category
}

fn .r {|*|
	# Help tag: related
}

fn .f {|*|
	# Help tag: features
}

fn .i {|*|
	# Help tag: informational
}

fn .libi {|*|
	# Print information about a given function.
        {~ <={result $#(fn-$*)} 0} && {
                throw error .libi 'not a function'
        }
        .ensure-libloc
        {~ <={%objget $libloc $*} ()} && {
                throw error .libi 'not in library'
        }
        %header-doc $* | nl -w2 -s': '
        printf \n'arglist : %s'\n'location: %s'\n \
                <={%argify `` \n {%arglist $*}} <={%objget $libloc $*}
}

fn .web-query {|site path query|
	# Web lookup primitive.
	if {~ $#query 0} {
		web-browser $site
	} else {
		let (q) {
			q = `{echo $^query|sed 's/\+/%2B/g'|tr ' ' +}
			web-browser $site^$path^$q
		}
	}
}

fn .adapt-resolution {|scale|
	# Adapt X and GTK resolution to that of primary display.
	# Scale is a float; default 1.0.
	let (scale = \
		<={if {result $scale} {result 1.0} else {result $scale}}; \
	screen; dpi) {
		catch {|e| echo $e '(retrying)'; sleep 0.2; throw retry} {
			(screen dpi) = <=%primary-display-dpi
		}
		dpi = <={%trunc `($scale*$dpi)}
		%with-tempfile tf {
			printf 'Xft.dpi: %d'\n $dpi >$tf
			xrdb -merge $tf
		}
		%with-tempfile tf {
			printf 'Xft/DPI %d'\n `($dpi*1024) >$tf
			xsettingsd -c $tf >[2]/dev/null &
			sleep 1
		}
		printf '%s @ %dppi'\n $screen $dpi
	}
}

fn .load_xspath {
	# Augment $PATH according to ./.xspath, if present.
	access -f .xspath && {
		# An .xspath file contains lines of the following forms.
		# Comments, extra lines, extra whitespace and trailing
		# blanks are prohibited. Each line must end with newline.
		#	v-- column 1
		#	%append-path `pwd
		#	%prepend-path `pwd
		#	%append-path `pwd^<relative-path>
		#	%prepend-path `pwd^<relative-path>
		if {`{cat .xspath|wc -l} :eq `{<.xspath grep -c \
			'^%\(ap\|pre\)pend-path `pwd\(\^/[^;]*\)\?$'}} {
			. .xspath
		} else {throw error .xsin '.xspath failed validation'}
		let (co = `{tput cols}) {
			var path | fold -sw `($co-4) | awk -f <{cat <<'EOF'
BEGIN {hd=0; cont=0}
{
	if (cont) {print "\\"; cont=0}
	if (hd) if (match($0, / $/)) print "  " $0 " \\"; else print "  " $0
}
/^path =/ {printf "%s", $0; hd=1; cont=1}
END {if (cont) printf "\n"}
EOF
			}
		}
	}
	true
}

fn .ensure-libdoc {
	let (df = ~/.cache/xslib/libdoc.$TERM; \
	fn-regen = {|tf|
		for f `{for e <={%split ' ' $$libloc} {
			echo $e|cut -d: -f1} |head -n-1|sort} {
				echo $f >>$tf
		}
		%split-xform-join {|infile outfile|
			%with-read-lines $infile {|f|
				printf \n%s \
					^------------------------------------ \
					^------------------------------------ \
					^%s\n%s%s%s\n\n \
					<=.%ad <=.%an \
					<={if {fgconsole >/dev/null >[2=1]} {
						result <={.%af 2}
					} else {
						result <=.%ab^<=.%ai
					}} \
					$f <=.%an
				%ignore-error {.libi $f}
			} >>$outfile
		} 5 $tf `mktemp $tf
	}) {
		mkdir -p ~/.cache/xslib
		if {%outdated $df `{/usr/bin/ls ~/.xs*.d/*.xs}} {
			%with-tempfile tf {
				if {tty -s} {
					%with-throbber 'Regenerating... ' {
						.ensure-libloc
						regen $tf
					}
				} else {
					notify libdoc Regenerating...
					.ensure-libloc
					regen $tf
				}
				cat <{printf '%s%-72s%s' \
					<={if {fgconsole >/dev/null >[2=1]} {
						result <=.%ar
					} else {
						result <=.%ah
					}} \
					'Library functions' \
					<={if {fgconsole >/dev/null >[2=1]} {
						result <=.%an
					} else {
						result <=.%ahe}
					}} \
					$tf >$df
			}
		}
	}
}

fn .ensure-libloc {
	~ $libloc () && let (cf = ~/.cache/xslib/libloc; tf = `mktemp) {
		mkdir -p ~/.cache/xslib
		if {%outdated $cf ~/.xs*.d/*.xs /usr/local/src/XS/src/*.xs} {
			%safe-wild '~/.xs*.d/*.xs' \
					^':/usr/local/src/XS/src/*.xs' {|exp|
				for f $exp {
					nl -ba -fn -hn -nln -s: -w1 $f \
						|sed 's|^|'$f^':|'>>$tf
				}
			}
			let (of = `mktemp) {%split-xform-join {|srcf dstf|
				grep -o '^\([^:]\+:\)\{2\} *' \
						^'\(fn\|%cfn {[^}]\+}\)' \
						^' [^{ ]\+' $srcf \
					|sed 's/: *' \
						^'\(fn\|%cfn {[^}]\+}\)' \
						^' /:/' >$dstf
				} 1 $tf `mktemp $of
				libloc = <=%mkobj
				for lf `{cat $of} {
					let ((f ln nm) = <={~~ $lf *:*:*}) {
						%objset-nr $libloc $nm $f^:$ln
					}
				}
			}
			%objpersist $libloc $cf
		} else {
			libloc = <={%objrestore $cf}
		}
	}
}

fn .build-appmenu {
	# Modify the cwm configuration to build the apps menu.
	let (wmcf = ~/.cwmrc; apps) {
		ed -ls $wmcf <<EOF
g/^command /d
wq
EOF
		apps = \
			`` '' {vars -f \
				|sed 's/{\.\(a\|c\|i\|d\|r\) [^}]*}//g' \
				|grep -Fw -e %with-terminal \
				|grep -o '^fn-[^ ]\+'|cut -d- -f2- \
				|grep '^[a-z0-9]'} \
			`` '' {/usr/bin/ls /usr/share/applications/*.desktop \
				|xargs grep -L Terminal=true \
				|xargs -n1 -I\{\} basename \{\} .desktop \
				|grep -v '\.' \
				|grep -v -f ~/.local/appmenu-exclude}
		for f (`{echo $apps|sort|uniq}) {
			echo command $f "xs -c $f^" >>$wmcf
		}
	}
}
