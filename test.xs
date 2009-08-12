#!./xs
VERBOSE := false
if $VERBOSE { DOTARGS := -v }

let (TMPOUT := /dev/shm/xs.$pid.testout) {
    # Ends up without newlines
    fn output {
        cat $TMPOUT
    }
    fn run name code {
	let (dir := /dev/shm/xs.$pid) {
		rm -fr $dir
		mkdir $dir
		cd $dir
	}
        TESTNAME := $name
	log2 Running $name...
        RETURNVALUE := <={fork {$code >$TMPOUT >[2=1]}}
	log2 Done running $name....
	log2 $TESTNAME produced output:
	log2 `output
	log2 $TESTNAME exited:
	log2 $RETURNVALUE
    }
}

let (passes := 0
     fails  := 0)
{
    fn pass { 
	passes := `{expr 1 + $passes}
        log 'Passed: ' $TESTNAME
    }
    fn fail { 
	fails := `{expr 1 + $fails} 
	log 'Failed: ' $TESTNAME
    }
    fn results {
	log 'Expected passes:     ' $passes
	log 'Unexpected failures: ' $fails
    	rm -r /dev/shm/xs.*
	exit $fails
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
    ! expect-success
}
fn match result {
    log2 Matching...
    ~ `` '' output *^$^result^*
}
fn match_re result {
    log2 Match_re....
    eval '~ `` '''' output *'^$^result^'*'
}
let (dir := `pwd 
     logfile := `pwd^/xs.log) 
{
    fn log msg {
        echo $msg | tee -a $logfile
    }
    fn log2 msg {
	if $VERBOSE { log $msg } {echo $msg >> $logfile}
    }

    rm -f $logfile
    for (file := $dir/xs_tests/*.xs) {
	log2 Running $file
	local (FILE := $file; XS := $dir/xs) . $DOTARGS $FILE
    }
    cd $dir
}
results
