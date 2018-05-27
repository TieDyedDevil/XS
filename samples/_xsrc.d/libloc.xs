fn .ensure-libloc {
	~ $libloc () && {
		libloc = <=%mkobj
		%safe-wild '~/.xs*.d/*.xs:/usr/local/src/XS/src/*.xs' {|exp|
			for f $exp {
				for lf `{grep -nho 'fn [^ ]\+' $f \
							|sed 's/:fn /:/'} {
					let ((ln nm) = <={~~ $lf *:*}) {
						%objset $libloc $nm $f^:$ln
					}
				}
			}
		}
	}
}

fn refresh-libloc {
	.d 'Refresh library location database.'
	.c 'system'
	%rmobj $libloc
	libloc =
}
