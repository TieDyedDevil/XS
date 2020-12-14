local (FORK = false; ssig = $signals; signals = $signals) {

# The testing framework uses FORK = true by default. Doing so simplifies
# "starting fresh" for each test: fork {...} creates a clone which can be
# freely manipulated then abandoned, leaving the next test to have the
# same initial state as the last.
#
# XS does not process signals in a clone. (See hasforked in the source.)
#
# Because all of these tests run in the same (uncloned) shell, we must be
# careful to leave the shell in the same state at the conclusion of these
# tests as it was at the start.

run 'signals update' {
	signals = $ssig sigttou
	echo $signals
}
conds { match sigttou }

run 'signals-case' {
	signals = $ssig sigttou
	signals-case {kill -sigttou $pid} (sigttou {echo sigttou})
}
conds { match sigttou }

run 'Signal bypass catch' {
	signals = $ssig sigttou
	signals-case {
		catch {|e| echo catch $e} {kill -sigttou $pid}
	} (sigttou {echo sigttou})
}
conds { match sigttou }

run 'Exception inside signals-case' {
	signals = $ssig sigttou
	signals-case {
		catch {|e| echo catch $e} {throw error a b c}
	} (sigttou {echo sigttou})
}
conds { match catch error a b c }

run 'Exception bypass signals-case' {
	signals = $ssig sigttou
	catch {|e|
		echo catch $e
	} {
		signals-case {throw error a b c} (sigttou {echo sigttou})
	}
}
conds { match catch error a b c }

run 'Signal inside catch' {
	signals = $ssig sigttou
	catch {|e|
		echo catch $e
	} {
		signals-case {kill -sigttou $pid} (sigttou {echo sigttou})
	}
}
conds { match sigttou }

run 'raise' {
	signals-case {raise something} (something {echo something})
}
conds { match something }

run '$pid inside fork {...}' {
	ppid = $pid
	fork { $pid :ne $ppid && echo pass }
}
conds { match pass }

run '$signals initially () inside fork {...}' {
	fork { ~ $signals () && echo pass }
}
conds { match pass }

run '$signals always () inside fork {...}' {
	fork { signals = sigint; ~ $signals () && echo pass }
}
conds { match pass }

} # local (...) ...
