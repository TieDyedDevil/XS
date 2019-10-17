fn %make-counter {
	# Return a function which returns consecutive counting numbers.
	let (c = 0) {
		let (fn-a = {c = `($c+1); result $c}) {
			result $fn-a
		}
	}
}

let (g = 0) {
	fn %gensym {
	# Generate a "unique" name.
		let (n = \xff\xff^`{printf G%04u $g}) {
			g = `($g+1)
			result $n
		}
	}
}

fn %list {|*|
	# Given a comma-separated list of tokens, return a list of tokens.
	let (f; r = $*; l) {
		while {!~ $r ()} {
			if {~ $r *,*} {(f r) = <={~~ $r *,*}} else {(f r) = $r}
			l = $l $f
		}
		result $l
	}
}

fn %argify {|*|
	# Always return a one-element list.
	result $^*
}

fn %aset {|name index value|
	# Emulate indexed assignment.
	\xff^$name[$index] = $value
}

fn %asetm {|name value indices|
	# Emulate multidimensional indexed assignment.
	let (n_ = \xff^$name; i_) {
		for i_ $indices {n_ = $n_^[$i_]}
		eval \{ $n_ \= $value \}
	}
}

fn %aref {|name index|
	# Emulate indexed retrieval.
	result $(\xff^$name[$index])
}

fn %arefm {|name indices|
	# Emulate multidimensional indexed retrieval.
	let (n_ = \xff^$name; i_) {
		for i_ $indices {n_ = $n_^[$i_]}
		result $($n_)
	}
}

fn %mkobj {
	# Create an object; return its name.
	let (nm = go; go = go) {
		while {!~ $($nm) ()} {nm = \xff^objid:^<=$&random}
		$nm = obj
		result $nm
	}
}

fn %rmobj {|objname|
	# Destroy a named object.
	eval $objname^' ='
}

fn .objcheck {|objname|
	# Throw an error if objname does not name an object.
	if {{~ $objname ()} || {!~ $($objname) obj *\ obj}} {
		throw error object 'Not an object: '^$objname
	}
}

fn .objkeyenc {|key|
	# Encode object key.
	echo -n -- $key|tr : \010
}

fn .objkeydec {|key|
	# Decode object key.
	echo -n -- $key|tr \010 :
}

fn %objset {|objname key value|
	# Set an object field.
	.objcheck $objname
	%objunset $objname $key
	$objname = `{.objkeyenc $key}^:^$value $($objname)
}

fn %objset-nr {|objname key value|
	# Set an object field without replacing keys.
	.objcheck $objname
	$objname = `{.objkeyenc $key}^:^$value $($objname)
}

fn %objunset {|objname key|
	# Remove an object field.
	.objcheck $objname
	let (ov = $($objname); ekey = `{.objkeyenc $key}; rv) {
		for kv $ov {
			{!~ $kv $ekey:*} && {rv = $rv $kv}
		}
		$objname = $rv
	}
}

fn %objget {|objname key default|
	# Get an object field.
	.objcheck $objname
	let (v = <={~~ $($objname) `{.objkeyenc $key}^:*}) {
		if {!~ $v ()} {result $v} else {result $default}
	}
}

fn %objkeys {|objname|
	# Return list of object keys.
	.objcheck $objname
	let (ov = $($objname); entry; kn; keys) {
		for entry $ov {
			(kn _) = <={~~ $entry *:*}
			keys = `{.objkeydec $kn} $keys
		}
		result $keys
	}
}

fn %obj-isempty {|objname|
	# True if object has no fields.
	.objcheck $objname
	result <={!~ $($objname) *:*}
}

fn %objreset {|objname|
	# Remove all fields from an object.
	.objcheck $objname
	$objname = obj
}

fn %objpersist {|objname path|
	# Persist named object to path.
	.objcheck $objname
	echo -n $objname $($objname) >$path
}

fn %objrestore {|path|
	# Restore object from path and return object's ID.
	let (t = `` ' ' {cat $path}; n; v) {
		n = $t(1)
		v = $t(2 ...)
		$n = $v
		result $n
	}
}

fn %objlog {|objname path|
	# Log named object to path. Return the name.
	# The log file must be initialized empty.
	.objcheck $objname
	echo $objname $($objname) >>$path
	result $objname
}

fn %objreplay {|path|
	# Restore objects from log.
	# The log file must have been created using %objlog.
	%with-read-lines $path {|line|
		let (t = `` ' ' {echo $line}) {
			eval $t(1) \= $t(2 ...)
		}
	}
}

fn %mkdict {|*|
	# Make a dictionary from a list of key/value pairs.
	# Keys are unique.
	let (d = <=%mkobj) {
		while {!~ $* ()} {
			let ((k v) = $*(1 2)) {%objset $d $k $v}
			* = $*(3 ...)
		}
		result $d
	}
}

fn %mkbag {|*|
	# Make a bag from a list of key/value pairs.
	# Keys are nonunique.
	let (d = <=%mkobj) {
		while {!~ $* ()} {
			let ((k v) = $*(1 2)) {%objset-nr $d $k $v}
			* = $*(3 ...)
		}
		result $d
	}
}

fn %with-object {|lambda|
	# Execute lamba, passing a fresh object.
	# The object is disposed upon leaving the lambda.
	let (__o = <=%mkobj) {
		unwind-protect {
			$lambda $__o
		} {
			$__o =
		}
	}
}

fn %with-dict {|lambda pairs|
	# Execute lambda, passing a fresh object initialized with pairs.
	# The object is disposed upon leaving the lambda.
	let (__o = <={%mkdict $pairs}) {
		unwind-protect {
			$lambda $__o
		} {
			$__o =
		}
	}
}

fn %parse-bool {|*|
	# Parse common truth values.
	if {~ $* y Y yes Yes YES 1 t T true True TRUE} {
		true
	} else if {~ $* n N no No NO 0 f F false False FALSE} {
		false
	} else {
		throw error %parse-bool 'not a truth value: '$^*
	}
}

fn %plural {|*|
	# Return '' if the given number is 1, otherwise return 's'.
	if {~ $* 1} {result ''} else {result 's'}
}

fn %strip-csi {
	# Filter strips ANSI CSI sequences.
	sed 's/\x1B\[[0-9;]*[a-zA-Z]//g'
}

fn %strip-ctl {
	# Filter strips control characters, preserving tab and newline.
	tr -d \x01-\x08\x0b-\x1f
}

fn %prefixes {|word min|
	# Return all prefixes of word.
	# If specified, min is length of shortest prefix.
	let (r; i = $min; l = <={$&len $word}) {
		~ $i () && i = 1
		while {$i :le $l} {
			r = $r `{echo $word|cut -c 1-$i}
			i = `($i+1)
		}
		result $r
	}
}

fn %as-bool {|*|
	# Convert args to boolean.
	# (), '' and 0 are true; everything else is false.
	if {~ $* ()} {
		result true
	} else {
		let (r) {
			for v $* {
				if {result $v} {
					r = $r true
				} else {
					r = $r false
				}
			}
			result $r
		}
	}
}

fn %rgbhex {|color|
	# Emit a hex color code given the same or an X11 color name
	if {~ `{echo $color|cut -c1} '#'} {
		printf %s $color
	} else {
		let (rgb = `{grep -wi '\W'^$^color^'$' /usr/share/X11/rgb.txt \
				|cut -c1-11}){
			~ $rgb () && throw error %rgbhex 'color?'
			printf '#%02x%02x%02x' $rgb
		}
	}
}

fn %u {|cp|
	# Return the UTF-8 character denoted by its codepoint.
	eval result '\u'''$cp''''
}

fn %ord {|*|
	# Print decimal ordinal values of bytes in given word(s).
	hexdump -v -e '1/1 " %d"' <{echo -n $*}
}

fn %asort {
	# Sort by length, then by name.
	%with-read-lines /dev/stdin {|line|
		let (len = <={$&len $line}) {
			printf %06d%s\n $len $line
		}
	} | sort | cut -c7-
}
