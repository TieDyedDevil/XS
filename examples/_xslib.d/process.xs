fn %running {|*|
	# Return true when process is running.
	# Accepts pgrep options.
	pgrep -c $* >/dev/null
}

fn %spawn-avoiding-duplication {|objname args body|
	# Spawn body (a lambda) in the background, passing args.
	# If this instance of %spawn-avoiding-reentry is currently
	# executing body, avoid reentry. The objname must be the
	# name of an object created by %mkobj and allocated in an
	# enclosing scope.
	#
	# WARNING: While suitable for cases where it's desirable
	# to not run a body already in execution (e.g. to avoid
	# spawning two instances of the same long-running task),
	# %spawn-avoiding-duplication must *not* be used where an
	# occasional reentry will cause your program to fail.
	#
	# Example:
	# let (lockobj = <=%mkobj) {
	#     for i <={%range 1-9} {
	#         echo invoke $i
	#         %spawn-avoiding-duplication $lockobj 7 {|*|
	#             sleep $*  # we're busy...
	#             echo executed with arg $*
	#         }
	#         echo return $i
	#         sleep 1
	#     }
	# }
	if <={%objget $objname ready true} {
		%objset $objname ready false
		unwind-protect {
			$body $args
		} {
			if {! <={%objget $objname ready}} {$body $args}
			%objset $objname ready true
		} &
	}
}
