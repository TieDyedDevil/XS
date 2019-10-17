## NOTE
# When first run, a browser window opens to authenticate and authorize
# Google Calendar access.

## IMPORTANT
# These tools must be configured by putting the desired calendar name
# in ~/.config/gcalcli-calendar. Valid calendar names are displayed
# using `gcalcli list`.

fn agenda {|*|
	.d 'Google calendar agenda'
	.a '[start_time [end_time]]'
	.c 'web'
	%with-terminal agenda {cat <{date} <{gcalcli agenda --nodeclined $*} \
				|%wt-pager -r}
}

fn gcal {|*|
	.d 'Google calendar for week(s) or given month'
	.a '[NUMBER_OF_WEEKS|MONTH_NAME]'
	.c 'web'
	%with-terminal gcal {
		if {~ $* () || ~ $* [1-9]} {
			gcalcli calw '' $*
		} else {
			gcalcli calm $*
		} | %wt-pager -r
	}
}

fn gcalcli {|*|
	.d 'gcalcli'
	.a '[gcalcli_OPTIONS]'
	.f 'wrap'
	let (cf = ~/.config/gcalcli-calendar; cal) {
		access -f $cf && cal = --calendar `` \n {cat $cf}
		%with-tempfile o {
			/usr/bin/gcalcli $cal $* >[2]$o || {
				throw error gcalcli `{tail -n-1 $o}
			}
		}
	}
}

fn gcal-add {|*|
	.d 'Add an event to Google calendar'
	.a 'FREEFORM_EVENT_INFO...'
	.c 'web'
	if {~ $#* 0} {
		.usage gcal-add
	} else {
		gcalcli quick $^*
	}
}

fn gcal-delete {|*|
	.d 'Delete an event from Google calendar'
	.a 'EVENT_TITLE...'
	.c 'web'
	if {~ $#* 0} {
		.usage gcal-delete
	} else {
		gcalcli delete $^*
	}
}

fn gcal-edit {|*|
	.d 'Edit an event on Google calendar'
	.a 'EVENT_TITLE...'
	.c 'web'
	if {~ $#* 0} {
		.usage gcal-edit
	} else {
		gcalcli edit $^*
	}
}

fn gcal-web {
	.a 'Google calendar in a browser'
	.c 'web'
	%only-X
	web https://calendar.google.com
}

fn gcal-remind {|*|
	.d 'Google calendar notifier'
	.a '[off]'
	.c 'system'
	let (rmpid = ~/.local/share/gcal-remind.pid) {
		if {$#* :ge 1 && !~ $* off} {
			.usage gcal-remind
		} else if {~ $* off} {
			if {access -f $rmpid} {
				pkill -g `{cat $rmpid}
				echo 'Stopped'
				rm -f $rmpid
			}
		} else if {{access -f $rmpid} \
				&& {kill -0 `{cat $rmpid} >[2]/dev/null}} {
			echo 'Running'
		} else setsid xs -c {
			let (lead = 5; cycle = 15) {
				let ( \
				fn-sync = { \
					let (seg; pause; \
					(minute second) = `{date +%M\ %S} \
					) {
						seg = `($minute%$cycle)
						pause = `($cycle-$seg-$lead)
						~ $pause -* 0 && \
							pause = \
							  `($cycle+$pause)
						sleep `(60*$pause-$second)
					}
				}; \
				fn-check = {
					let (rems = `` \n {gcalcli remind \
							$lead 'echo %s'}) {
						for text $rems {
							notify persist\| \
								^Reminder \
								$text
							sleep 2.5
						}
					}
				} \
				) {
					echo 'Started'
					while true {
						sync
						check
					}
				} &
				echo $apid > $rmpid
			} &
			echo $apid > $rmpid
		}
	}
}
