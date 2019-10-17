fn %args {|*|
	# Given a list of command-line arguments where the list contains N
	# elements, return a 2N-element list where each pair of elements
	# corresponds to one element of the argument. The first element of
	# each pair is always an option flag; the second is always a non-
	# option argument. The absence of a flag or argument is denoted by
	# _ in the result list. Tokens following a -- option are all treated
	# as arguments, even in the case where a token begins with -.
	let (r = $*; l) {
		while {!~ $r ()} {
			let (f; m = '_') {
				(f r) = $r
				if {~ $f --} {
					l = $l $f $m
					while {!~ $r ()} {
						(f r) = $r
						l = $l $m $f
					}
				} else if {~ $f -*} {
					let ((a b) = $r) {
						if {~ $a -*} {
							l = $l $f $m
						} else {
							{~ $a ()} && a = $m
							l = $l $f $a
							r = $b
						}
					}
				} else {
					l = $l $m $f
				}
			}
		}
		result $l
	}
}

fn %parse-args {|*|
	# Given the output of %args followed by \& and a list of option/
	# thunk pairs to be used for processing options, process the
	# options and a return a list of the non-option words optionally
	# followed by -- and following words. Within the option thunks,
	# the option and its value are denoted $optopt and $optval.
	let (a; cases) {
		let (o; v; l = $*) {
			{escape {|fn-break| while {!~ $l ()} {
				(o v l) = $l
				{~ $o \&} && {l = $v $l; break}
				a = $a $o $v
			}}}
			cases = $l
		}
		let (l = $a; words; extra) {
			while {!~ $l ()} {
				(optopt optval l) = $l
				if {~ $extra(1) --} {extra = $extra $optval} \
				else switch $optopt (
					_ {words = $words $optval}
					-- {extra = $optopt}
					$cases
					{throw error %parse-args \
						'opt? '^$optopt}
				)
			}
			result $words $extra
		}
	}
}

fn %menu {|*|
	# Present a menu. The argument list is a header followed by
	# a list of <key, title, action, disposition> tuples.
	# The action does not have access to lexical variables.
	# Disposition is either C (continue after action) or B (break
	# after action). Keystrokes are processed immediately.
	# These keys are always recognized: Return to draw the menu;
	# ^L to clear the screen and draw the menu; ^D to exit.
	let (hdr; l; mt; ma; key; title; action; cb; c; a; none = <=%gensym; \
	esc = false; csi = false; csiO = false; csterm = a b c d e f g h i j \
	k l m n o p q r s t u v w x y z A B C D E F G H I J K L M N O P Q R \
	S T U V W X Y Z \~; ctrl = \x01 \x02 \x03 \x05 \x06 \x07 \x08 \x09 \
	\x0a \x0b \x0c \x0e \x0f \x10 \x11 \x12 \x13 \x14 \x15 \x16 \x17 \
	\x18 \x1a \x1c \x1d \x1e \x1f; row; col) {
	let (fn-erase = {tput cup `($row-1) `($col-1); tput ed}) {
		hdr = $*(1); * = $*(2 ...)
		ma = <=%mkobj
		while {!~ $* ()} {
			(key title action cb) = $*(1 2 3 4); * = $*(5 ...)
			mt = $mt $key $title
			%objset $ma $key $action $cb
		}
		escape {|fn-break|
			while true {
				escape {|fn-redisplay|
				!~ <={$&len $hdr} 0 && printf %s\n $hdr
				l = $mt
				while {!~ $l ()} {
					(key title) = $l(1 2); l = $l(3 ...)
					printf %c\ %s\n $key $title
				}
				while true {
					!$esc && !$csi && !$csiO && {
						(row col) = \
							<=%get-cursor-position
						printf \?\ 
					}
					c = <=%read-char
					!$esc && ~ $c \n && redisplay
					!$esc && ~ $c \x0c && {
						clear
						redisplay
					}
					~ $c \x04 && break
					if {~ $c \x1b || $esc || $csi \
								|| $csiO} {
						{$csi || $csiO} \
							&& ~ $c $csterm && {
							csi = false
							csiO = false
							erase
						}
						$esc && ~ $c \[ && {
							csi = true
							esc = false
						}
						$esc && ~ $c O && {
							csiO = true
							esc = false
						}
						$esc && !~ $c \[ O \x1b && {
							esc = false
							erase
						}
						~ $c \x1b && {
							esc = true
							csi = false
							csiO = false
						}
					} else if {~ $c $ctrl} {
						erase
					} else {
						(a cb) = <={%objget $ma $c \
									$none}
						if {!~ $a $none} {
							printf \n
							$a
							~ $cb B && break
						} else {
							erase
						}
					}
				}}
			}
		}
		printf \n
	}}
}

fn %list-menu {|*|
	# Present a menu. The argument list is a header, a lambda,
	# and a list of items. The lambda is applied to the selected
	# item.
	let ((hdr action) = $*(1 2); l = $*(3 ...); i; n) {
		i = 0
		for n $l {
			i = `($i+1)
			echo $i $n
			%aset s $i $n
		}
		escape {|fn-break|
			while true {
				printf '#? '
				n = <=read
				~ $n () && {printf \n; break}
				if {echo $n|grep -q '^[[:digit:]]\+$'} {
					i = <={%aref s $n}
					{!~ $i ()} && {$action $i; break}
				}
			}
		}
	}
}

fn %confirm {|dflt msg|
	# Query user for confirmation with default given as y or n.
	# Return true when confirmed.
	let (yes = <={if {~ $dflt y} {result Y} else {result y}}; \
	no = <={if {~ $dflt n} {result N} else {result n}}) {
		let (prompt = ' ['$yes'/'$no']? ') {
			escape {|fn-return| while true {
				printf %s%s $^msg $prompt
				c = <=read
				~ $c '' && c = $dflt
				~ $c () && c = $dflt
				switch $c (
				y {return <=true}
				n {return <=false}
				{}
				)
			}}
		}
	}
}

fn %with-throbber {|msg body|
	# Run body while displaying msg and an animated throbber.
	%without-cursor {
		let (animation; fn-spinner = {
			while true {
				printf '*'; sleep 0.5; printf \b
				printf '@'; sleep 0.5; printf \b
			}
		}) {
			unwind-protect {
				spinner &
				printf \r$msg
				animation = $apid
				$body
			} {
				kill $animation
			}
		}
	}
}

fn %choose-directory {|title initial-path|
	# Return a directory path selected interactively, or () if cancelled.
	%choose-in-filesystem d $title $initial-path
}

fn %choose-file {|title initial-path|
	# Return a file path selected interactively, or () if cancelled.
	%choose-in-filesystem f $title $initial-path
}

fn %choose-in-filesystem {|type title initial-path|
	# Return a filesystem entry selected interactively, or () if cancelled.
	# The type of the selectable item is one of {bcdpfls}, corresponding
	# to the parameter of find(1)'s -type predicate. The type is required.
	# The title, if omitted or '', is based upon the type.
	# The initial path is . if not specified.
	local (dt; type = $type) {
	switch $^type (
	b {dt = 'block special'}
	c {dt = 'character special'}
	d {dt = 'directory'}
	p {dt = 'named pipe'}
	f {dt = 'regular file'}
	l {dt = 'symbolic link'}
	s {dt = 'socket'}
	{throw error %choose-in-filesystem 'type?'}
	)
	~ $title () || ~ $title '' && title = 'Choose '^$dt
	~ $initial-path () && initial-path = '.'
	local ( \
	fn-qq = {|w| result `` \n {printf %s\n $w|sed 's/''/''''/g'}}; \
	fn-fr = {|flg| if {~ $flg ()} {result -v '/\.'} else {result '.'}} \
	) {
	local ( \
	ml; af; lo; r = $initial-path; pf = ''; run = true; \
	fn-hs = {|flg| ~ $flg () && echo hidden || echo shown}; \
	fn-dl = {|init match aflg|
		let (mi = 1; f1 = <={fr $aflg}; ec) {%with-tempfile tf {
			result `` \n {
				for d (
				`` \n {find $lo $init -mindepth 1 -maxdepth 1 \
						\( -type d -o -type $type \) \
					|grep $f1|sort \
					|grep -F $match \
					|tee >{wc -l >$tf} \
					|head -9}
				) {
					echo $mi
					echo $d
					echo '{r = '''^<={qq $d}^'''; ' \
						^'pf = ''''}'
					echo B
					mi = `($mi+1)
				}
				ec = `{cat $tf}
				if {$ec :gt 9} {
					echo ' '
					echo `.as^'<+'^`($ec-9)^' more>'^`.an
					echo '{}'
					echo B
				} else if {~ $ec 0} {
					echo ' '
					echo `.as^'<no matched entry>'^`.an
					echo '{}'
					echo B
				}
			}
		}}} \
	) {
		while {$run} {
			~ $title '' || printf '%s%s%s'\n <=.%au $title <=.%an
			ml = <={dl $r $pf $af}
			%menu 'Select ['^<=.%as^$r^<=.%an^']:' (
			- '../' {r = `` \n {dirname $r}} B
			$ml
			. 'Show/hide dotfiles ['^<=.%as^`{hs $af}^<=.%an']' {
				if {~ $af ()} {af = -A} else {af = ()}
				} B
			<={if {!~ $type l} {result \
			, 'Show/hide symlinks ['^<=.%as^`{hs $lo}^<=.%an']' {
				if {~ $lo ()} {lo = -L} else {lo = ()}
				} B
				} else {result ()}
			}
			/ 'Filter ['^<=.%as^$pf^<=.%an^']' {
				printf 'match> '; pf = <=read
				} B
			l 'List all' {find $lo $r -mindepth 1 -maxdepth 1 \
						\( -type d -o -type $type \) \
					|grep <={fr $af}|sort|less -eX} B
			<={if {access -^$type $r} {result \
			s 'Select '^$dt^' ['^<=.%as^`` \n {basename $r} \
								^<=.%an^']' {
				{run = false}
				} B
				} else {result ()}
			}
			c 'Cancel' {r = (); run = false} B
			)
		}
		result $r
	}
	}
	}
}
