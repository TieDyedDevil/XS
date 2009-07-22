#!./xs
VERBOSE := false
if $VERBOSE { DOTARGS := -v }
fn arith cmds {
    echo $cmds | bc
}

let (TMPOUT := /dev/shm/xs.$pid.testout) {
    # Ends up without newlines
    fn output {
        cat $TMPOUT
    }
    fn run name code {
	let (dir := /dev/shm/xs.$pid.`{basename $FILE}) {
		mkdir -p $dir
		cd $dir
	}
        TESTNAME := $name
	log2 Running $name...
        RETURNVALUE := <={eval $code >$TMPOUT >[2=1]}
	log2 Done running $name....
	log2 $TESTNAME produced output:
	log2 `{output}
	log2 $TESTNAME exited:
	log2 $RETURNVALUE
    }
}

let (passes := 0
     fails  := 0)
{
    fn pass { 
	passes := `{arith 1 + $passes}
        log 'Passed: ' $TESTNAME
    }
    fn fail { 
	fails := `{arith 1 + $fails} 
	log 'Failed: ' $TESTNAME
    }


    fn results {
	    log 'Expected passes:     ' $passes
	    log 'Unexpected failures: ' $fails
	    if {test $fails -eq 0} exit 0
	    else exit $fails
    }
}
fn conds requirements {
    for (req := $requirements) {
    	if {! eval $req} { 
    	    fail
    	    return
    	}
    }
    pass
}
fn expect-success {
    return $RETURNVALUE
}
fn expect-failure {
    return <={! expect-success}
}
fn match result {
    log2 Matching...
    return <={~ `` '' {output} *^$^result^* }
}
fn match_re result {
    log2 Match_re....
    return <={eval '~ `` '' {output} *'^$^result^'*' }
}
let (dir := `{pwd} 
     logfile := `{pwd}^/xs.log) {
    rm -f $logfile
    fn log msg {
        echo $msg | tee -a $logfile
    }
    fn log2 msg {
	if $VERBOSE { log $msg } {echo $msg >> $logfile}
    }
    for (file := $dir/xs_tests/*.xs) {
        local (FILE := $file; XS := $dir/xs) . $DOTARGS $FILE
    }
}
results
rm -r /dev/shm/xs.*
