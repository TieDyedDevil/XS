#! /usr/bin/env xs

# Requirements:
#  * xs 1.1; https://github.com/TieDyedDevil/XS (or Fedora 27 distro).
#  * Linux with usual tools packages (coreutils, gawk, grep, sed, ...).
#  * The additional tools listed just below the ARCHITECTURE diagram.
#
#  The wm, upon receipt of the quit hook, simply exits. This doesn't give
#  the panel a chance to clean up; the residue will interfere with the
#  proper startup of subsequent panels. To shut down the panel cleanly,
#  bind the following shell script to the wm's quit key:
#    herbstclient emit_hook quit panel
#    sleep 1
#    herbstclient quit

# Purpose: Display a panel for herbstluftwm.
#
# Goals: low power consumption (given the constraints of being written in a
# shell language); good visual integration with wm; focus attention on the
# most important elements; properly clean up resources upon termination and
# restart.
#
# Non-goals: pointer integration; keyboard control; configurability beyond
# that already provided; support for "light" themes; non-Linux OS support;
# in-process recovery from improper termination of previous session.
#
# The panel is divided into three regions. The left region contains tag
# indicators, alert and status indicators, a CPU load bar and the title of
# the focused window. The center region shows info for the track being
# played by mpd. The right region shows a clock.
#
# The alert indicators are:
#   B low battery
#   D high disk space utilization
#   F fan failure (temperature rise w/stopped fan)
#   I high I/O utilization of physical block device
#   L 1-minute load average exceeds number of available processors
#   S swapfile in-use
#   T high temperature
#
# The status indicators are:
#   4 an IPv4 connection exists
#   6 an IPv6 connection exists
#   A AC power to mobile device
#   B Bluetooth device connection active
#   C CDMA cellular connection active
#   E Ethernet connection active
#   G GSM cellular connection active
#   I inbox flag
#   M mouse keys active
#   N network connected              | one; not both
#   n network connected to a portal  | one; not both
#   V VPN connection active
#   W WiFi connection active
#   Z screensaver is enabled
#   " host is virtualized
#
# Inbox status requires a valid inbox.fetchmailrc file in the same
# directory as this script; see fetchmail(1). The fetchmail configuration
# *must* specify `no idle` and *should* specify `timeout 15`.
#
# Alerts are displayed as short messages on the OSD if triggered when the
# panel is concealed by a fullscreen window. The battery-critical alert
# is always displayed on the OSD regardless of whether the focused window
# is fullscreen.
#
# With the exception of the tag indicators and title, panel content may
# be enabled selectively, whether for cosmetic or functional preference
# or to further reduce the panel's already low CPU load.
#
# The panel "borrows" some of the colors defined by the wm, as follows:
#   frame_border_normal_color
#     Used as the primary background color. Used as the foreground color
#     for selected, unfocused and urgent tags.
#   frame_border_active_color
#     Used as the background color for unfocused tags.
#   frame_bg_normal_color
#     Used as the background color for unfocused tags on an unfocused monitor.
#   frame_bg_active_color
#     Used as the background color for an focused tag on an unfocused monitor.
#     Used as the foreground color for unfocused tags on an unfocused monitor.
#   window_border_normal_color
#     Used as the foreground color for unfocused tags and the track and
#     clock text.
#   window_border_active_color
#     Used as the background color for the selected tag.
#   window_border_urgent_color
#     Used as the background color for urgent tags.
#
# Additional panel colors are hardwired and presume a "dark" wm theme.

# ========================================================================
#                      C O N F I G U R A T I O N

# Presentation
panel_height_px = 22
panel_font = 'NotoSans-14'         # XLFD or Xft
show_alert_placeholders = false
show_status_placeholders = false

trackfmt = '%title%'               # mpc(1)
clockfmt = '%a %Y-%m-%d %H:%M %Z'  # date(1); one-minute resolution

osd_font = '-*-liberation mono-bold-r-*-*-*-420-*-*-*-*-iso10646-1'  # XLFD
osd_offset_px = 50
osd_dwell_s = 2

# Alert thresholds
battery_low_% = 10
battery_critical_% = 5
disk_full_% = 85
fan_margin_desktop_C = 50
fan_margin_mobile_C = 40
io_active_% = 70
temperature_margin_desktop_C = 25
temperature_margin_mobile_C = 15
swap_usage_% = 5

# Functionality, listed in presumed approximately-increasing order of CPU load
enable_track = true
enable_clock = true
enable_herbstclient = true  # value ignored; always enabled
enable_alerts = true
enable_network_status = true
enable_other_status = true
enable_cpubar = true
enable_inbox = true

# If true, write logger information to stderr
debug = false

# ========================================================================
#                       A R C H I T E C T U R E

# herbstclient& ------------------------------>----\   ; async
# clock& ------------------------------------->----|   ; poll/sleep (60s)
# mpc& --------------------------------------->----|   ; async
# cpu& --------------------------------------->----|   ; async
# alert& ------------------------------------->----|   ; poll/sleep (10s)
#   |                                              |
#   |      if (panel obscured or critical alert)   |
#   |      :                                       |
#   \------?-----+---> osdmsg| osd& + osd_cat      |   ; wait
#               /                                  |
# nothing& ----/                                   |   ; stdout = open
#             /    ----> trigger| lights& ---->----|   ; wait
#            /    /                                |
#   osd-client   /                                 |   ; cli (optional)
#               /    /------------------------<----/
# netstat& ----/     |                                 ; async
# other& -----/      |                                 ; poll/sleep ( 3s)
# inbox& ----/       |                                 ; poll/sleep (30s)
#                    \---> event| event-loop           ; wait
#                                  ... |
#        SERVER                   /   / \              ; poll/demux
#                                /   |   |
#    <---...--------------------/    |   |
#                                    |   |
#              /---------------------/   |
#   .   .   .  |.   .   .   .   .   .   .|  .   .   .   .   .   .   .   .
#              |                         |
#       .      v                  .      v                  .
#              |                         |
#       .   display| <--- hold&   .   display| <--- hold&   .
#              |                         |
#       .      v                  .      v                  .
#              |                         |
#       .    dzen2                .    dzen2                .
#
#       .         CLIENT 2        .         CLIENT 1        .

# ========================================================================
#             H  E  R  E     B  E     D  R  A  G  O  N  S
#             IOW: Change the following at your own risk.

# Override any extant aliases and check for existence of the binary
fn-dzen2 = <={access -1en dzen2 $path}
fn-dzen2-gcpubar = <={access -1en dzen2-gcpubar $path}
fn-fetchmail = <={access -1en fetchmail $path}
fn-hcitool = <={access -1en hcitool $path}
fn-herbstclient = <={access -1en herbstclient $path}
fn-iconv = <={access -1en iconv $path}
fn-iostat = <={access -1en iostat $path}
fn-lockfile = <={access -1en lockfile $path}
fn-mpc = <={access -1en mpc $path}
fn-nmcli = <={access -1en nmcli $path}
fn-osd_cat = <={access -1en osd_cat $path}
fn-sensors = <={access -1en sensors $path}
fn-systemd-detect-virt = <={access -1en systemd-detect-virt $path}
fn-xftwidth = <={access -1en xftwidth $path}
fn-xkbset = <={access -1en xkbset $path}
fn-xset = <={access -1en xset $path}

# What's our name?
ARG0 = $0
PGM = `{basename $ARG0}

# Get monitor info
monitor = $1
~ $monitor () && monitor = 0
geometry = `{herbstclient monitor_rect $monitor >[2]/dev/null}
~ $geometry () && {throw error $PGM 'Invalid monitor '^$monitor}
(x y panel_width _) = $geometry

# Here's a customization hook; use it at your own peril
access ~/.panel.xs && . ~/.panel.xs

# Carve out space for the panel
herbstclient pad $monitor $panel_height_px

# These files store the task and fifo info
taskfile = /tmp/panel-^$monitor^-tasks
fifofile = /tmp/panel-^$monitor^-fifos

# Define the common part of the fifo file names
tmpfile_base = `{mktemp -u /tmp/panel-XXXXXXXX}

# Define a logger, enabled by the debug variable
fn logger {|fmt args|
	if $debug {
		catch {|e|
			echo $PGM^': logger failed:' $e $fmt $args >[1=2]
		} {
			printf '%s: '^$fmt^\n $PGM $args >[1=2]
		}
	}
}

# Define utility functions
fn %with-read-lines {|file body|
	# Run body with each line from file.
	# Body must be a lambda; its argument is bound to the line content.
	<$file let (__l = <=read) {
		while {!~ $__l ()} {
			$body $__l
			__l = <=read
		}
	}
}

fn %argify {|*|
	# Always return a one-element list.
	if {~ $* ()} {result ''} else {result `` '' {echo -n $*}}
}

# Prepare the client for this monitor
dzen2_opts = -w $panel_width -x $x -y $y -h $panel_height_px \
	-e button3= -ta l -fn $panel_font
display = $tmpfile_base^-display-^$monitor
mkfifo $display

# ========================================================================
#                              C L I E N T

# There can be only one server...
pidfile = /tmp/panel-server.pid
dispfile = /tmp/panel.disp
clntfile = /tmp/panel.clnt
lockfile = /tmp/panel.lock
lockfile -1 $lockfile
checkpid = `{cat $pidfile >[2]/dev/null}
if {{access -f $pidfile} && {kill -0 $checkpid >[2]/dev/null}} {
	# Start a client for a non-server's display
	tail -f /dev/null >$display &
	client = $apid
	echo $display >>$dispfile
	echo $client >>$clntfile
	rm -f $lockfile
	logger 'client on monitor %d: %d; %d' $monitor $client $pid
	exec dzen2 <$display $dzen2_opts
	# CLIENT ENDS HERE
}

# ========================================================================
#                              S E R V E R

# Identify the server
logger 'server on monitor %d: %d' $monitor $pid
echo $pid >$pidfile

# Start a client for the server's display
tail -f /dev/null >$display &
client = $apid
echo $display >$dispfile
echo $client >$clntfile
rm -f $lockfile
dzen2 <$display $dzen2_opts &
logger 'client on monitor %d: %d; %d' $monitor $client $apid

# Define indicator placeholders
if $show_alert_placeholders {_a = '.'} else {_a = ''}
if $show_status_placeholders {_s = '.'} else {_s = ''}

# Fetch colors from wm
wm_fbn_color = `{herbstclient get frame_border_normal_color}
wm_fba_color = `{herbstclient get frame_border_active_color}
wm_fgn_color = `{herbstclient get frame_bg_normal_color}
wm_fga_color = `{herbstclient get frame_bg_active_color}
wm_wbn_color = `{herbstclient get window_border_normal_color}
wm_wba_color = `{herbstclient get window_border_active_color}
wm_wbu_color = `{herbstclient get window_border_urgent_color}

# Set fixed colors
panel_fg_color = '#f0f0f0'
panel_status_bg_color = '#003000'
panel_status_fg_color = '#00d000'
panel_alert_bg_color = '#400000'
panel_alert_fg_color = '#f00000'
cpu_fg_color = SkyBlue1
cpu_bg_color = SkyBlue4

# Report colors
logger 'palette: %s; %s; %s; %s; %s; %s; %s; %s; %s; %s; %s; %s; %s; %s' \
	<={%argify `{var panel_fg_color}} \
	<={%argify `{var panel_status_bg_color}} \
	<={%argify `{var panel_status_fg_color}} \
	<={%argify `{var panel_alert_bg_color}} \
	<={%argify `{var panel_alert_fg_color}} \
	<={%argify `{var wm_fbn_color}} \
	<={%argify `{var wm_fba_color}} \
	<={%argify `{var wm_fgn_color}} \
	<={%argify `{var wm_fga_color}} \
	<={%argify `{var wm_wbn_color}} \
	<={%argify `{var wm_wba_color}} \
	<={%argify `{var wm_wbu_color}} \
	<={%argify `{var cpu_fg_color}} \
	<={%argify `{var cpu_bg_color}}

# Define colors and bg/fg pairs
fgcolor = $panel_fg_color
bgcolor = $wm_fbn_color
selbg = $wm_wba_color
selfg = $bgcolor
occbg = $bgcolor
occfg = $fgcolor
unfbg = $wm_fba_color
unffg = $bgcolor
urgbg = $wm_wbu_color
urgfg = $bgcolor
dflbg = $bgcolor
dflfg = $wm_wbn_color
omdfg = $bgcolor
omdbg = $wm_fga_color
omufg = $wm_fga_color
omubg = $wm_fgn_color
stsbg = $panel_status_bg_color
stsfg = $panel_status_fg_color
alrbg = $panel_alert_bg_color
alrfg = $panel_alert_fg_color
sepbg = $bgcolor
sepfg = $selbg
cpubar_meter = $cpu_fg_color
cpubar_background = $cpu_bg_color

fn attr {|bg fg| printf '^bg(%s)^fg(%s)' $bg $fg}
normal_attr = `{attr $bgcolor $fgcolor}
selected_attr = `{attr $selbg $selfg}
occupied_attr = `{attr $occbg $occfg}
unfocused_attr = `{attr $unfbg $unffg}
urgent_attr = `{attr $urgbg $urgfg}
default_attr = `{attr $dflbg $dflfg}
om_default_attr = `{attr $omdbg $omdfg}
om_unfocused_attr = `{attr $omubg $omufg}
status_marker_attr = `{attr $stsbg $stsfg}
status_indicator_attr = `{attr $stsbg $stsfg}
alert_marker_attr = `{attr $alrbg $alrfg}
alert_indicator_attr = `{attr $alrbg $alrfg}
separator_attr = `{attr $sepbg $sepfg}

dzen2_gcpubar_opts = -h `($panel_height_px/2) \
	-fg $cpubar_meter -bg $cpubar_background \
	-i 1.5

osd_cat_opts = -f $osd_font -s 5 -c $alrfg \
	-i `($x+$osd_offset_px) -o `($y+$osd_offset_px+$panel_height_px) \
	-d $osd_dwell_s -w -l 1

# Create the status-lights trigger fifo
trigger = $tmpfile_base^-trigger-^$monitor
mkfifo $trigger

# Create the display event fifo
event = $tmpfile_base^-event-^$monitor
mkfifo $event

# Create the OSD message fifo
osdmsg = $tmpfile_base^-osdmsg-^$monitor
mkfifo $osdmsg

# Write fifo summary info
echo $event $trigger $osdmsg >$fifofile

# Initialize task pid tracker
taskpids =
fn rt {|*| taskpids = $taskpids $* $apid; echo $taskpids >$taskfile}

# Send window manager events
herbstclient --idle >$event &
rt herbstclient

# Send clock events
if $enable_clock {
	printf 'clock'\t'%s'\n <={%argify `{date +^$clockfmt}} >$event &
	while true {
		s = `{date +%s}
		sleep `(60-$s%60)
		printf 'clock'\t'%s'\n <={%argify `{date +^$clockfmt}}
	} >$event &
	rt clock
}

# Send player events
if $enable_track {
	mpc idleloop >$event &
	rt mpc
}

# Send CPU bar events
if $enable_cpubar {
	{
		dzen2-gcpubar $dzen2_gcpubar_opts \
			| stdbuf -oL sed 's/.*/cpubar'\t'&/' >$event
	} &
	rt cpu
}

# Start the OSD
tail -f /dev/null >$osdmsg &
rt nothing
<$osdmsg while true {
	osd_cat $osd_cat_opts
	sleep 1  # reached on $osdmsg EOF; shouldn't happen
} &
rt osd
fn osd {|msg| echo $msg >$osdmsg}

# If the panel is covered, use the OSD for alerts
fn alert_if_fullscreen {|fmt args|
	~ `{herbstclient attr clients.focus.fullscreen} true && {
		osd `{printf $fmt $args}
	}
}

# Send alert events
fn battery () {
	BAT = /sys/class/power_supply/BAT
	AC = /sys/class/power_supply/AC
	let (w = false; cap = 0; chg = 0; v) {
		if {{access -d $AC} && {~ `{cat $AC/online} 1}} {
			# We're on line power at the moment
		} else if {access -d $BAT^0} {
			for d $BAT? {
				if {~ `{cat $d/present} 1} {
					v = `{cat $d/energy_full}
					cap = `($cap+$v)
					v = `{cat $d/energy_now}
					chg = `($chg+$v)
				}
			}
			if {!~ $cap 0} {
				v = `(100.0*$chg/$cap)
				if {$v :lt $battery_low_%} {w = true}
			}
		}
		if {$v :le $battery_critical_%} \
			{osd 'Battery charge is critically low'}
		$w && {alert_if_fullscreen 'Battery charge < %d%%' \
			$battery_low_%}
		result $w
	}
}

fn disk () {
	VOLUMES = / /boot /home /run /tmp /var
	utilizations = `{df | less -n +2 | grep -w -e^$VOLUMES^\$ | tr -d % \
		| awk '{print $5 "\t" $6}'}
	escape {|fn-return| {
		for (occ name) $utilizations {
			if {$occ :gt $disk_full_%} {
				alert_if_fullscreen 'Disk > %d%% full' \
					$disk_full_%
				return true
			}
		}
		return false
	}}
}

HIGH = `{sensors|grep Package\\\|Physical|cut -d= -f2|cut -d\. -f1}
CHASSIS = `{cat /sys/devices/virtual/dmi/id/chassis_type}
fn get_setpoint {|margin_desktop_C margin_mobile_C|
	if {~ $CHASSIS ()} {
		result `($HIGH - $margin_desktop_C)
	} else if {{$CHASSIS :lt 8} || {$CHASSIS :gt 16}} {
		result `($HIGH - $margin_desktop_C)
	} else {
		result `($HIGH - $margin_mobile_C)
	}
}
TEMPERATURE_THRESHOLD = <={get_setpoint \
	$temperature_margin_desktop_C $temperature_margin_mobile_C}
FAN_THRESHOLD = <={get_setpoint $fan_margin_desktop_C $fan_margin_mobile_C}

fn get_curtemp {
	result `{sensors >[2]/dev/null|grep Package\\\|Physical \
			|cut -d: -f2|cut -d\. -f1|tr -d ' +'}
}

nofans_logged = false
fn fan () {
	speeds = `{sensors >[2]/dev/null|grep fan|cut -d: -f2|awk '{print $1}'}
	if {~ $speeds ()} {
		if {! $nofans_logged} {
			logger 'No fan sensors found'
			nofans_logged = true
		}
		result false
	} else {
		speed = 0; for s $speeds {speed = `($speed+$s)}
		if {{<=get_curtemp :gt $FAN_THRESHOLD} && {~ $speed 0}} {
			cycles = `($cycles+1)
			{$cycles :gt 1} && {
				alert_if_fullscreen 'Fan is stopped at %dC' \
					$FAN_THRESHOLD
				result true
			}
		} else {
			cycles = 0
			result false
		}
	}
}

fn io () {
	blkdevs = `{lsblk -dln -o name}
	escape {|fn-return| {
		%with-read-lines \
		<{iostat -dxy $blkdevs 3 1 \
			| awk '/^[^A-Z]/ {print $1 ":" $14}'} \
		{|line|
			(disk load) = <={~~ $line *:*}
			if {$load :gt $io_active_%} {
				alert_if_fullscreen 'I/O activity > %d%%' \
					$io_active_%
				return true
			}
		}
		return false
	}}
}

fn load () {
	la1m = `{cat /proc/loadavg|cut -d' ' -f1}
	cpus = `nproc
	if {$la1m :gt $cpus} {
		alert_if_fullscreen '1-minute load average > %d' $cpus
		result true
	} else {result false}
}

fn swap () {
	swapping = `{
tail -n +2 /proc/swaps | awk '
BEGIN { tot = 0; use = 0 }
{ tot += $3; use += $4; }
END { print ((use * 100 / tot) > '^$swap_usage_%^') }
'
	}
	if {~ $swapping 1} {
		alert_if_fullscreen 'Swapfile > %d%% full' $swap_usage_%
		result true
	} else {result false}
}

fn temperature () {
	if {<=get_curtemp :gt $TEMPERATURE_THRESHOLD} {
		alert_if_fullscreen 'Temperature > %dC' $TEMPERATURE_THRESHOLD
		result true
	} else {result false}
}

if $enable_alerts {
	b = $_a; d = $_a; f = $_a; i = $_a; l = $_a; s = $_a; t = $_a

	fn post_alert_event {
		echo alert\t$b$d$f$i$l$s$t >$event
	}

	post_alert_event &
	while true {
		if <=battery {b = B} else {b = $_a}
		if <=disk {d = D} else {d = $_a}
		if <=fan {f = F} else {f = $_a}
		if <=io {i = I} else {i = $_a}
		if <=load {l = L} else {l = $_a}
		if <=swap {s = S} else {s = $_a}
		if <=temperature {t = T} else {t = $_a}
		post_alert_event
		sleep 7  # io runs for 3 sec; total is 10
	} >$event &
	rt alert
}

# Send status events
if {~ <={systemd-detect-virt -q} 0} {
	is_virt = true
} else {
	is_virt = false
}

let (i4 = $_s; i6 = $_s; a = $_s; b = $_s; c = $_s; e = $_s; g = $_s; \
	ii = $_s; m = $_s; n = $_s; v = $_s; w = $_s; z = $_s; i" = $_s) {

	fn post_status_event {
		echo status\t$i4$i6$a$b$c$e$g$ii$m$n$v$w$z$'i"' >$event
	}

	fn update_network_status_lights {
		c = $_s; e = $_s; g = $_s; v = $_s; w = $_s
		i4 = $_s; i6 = $_s; n = $_s
		let (net_type; dev) {
			%with-read-lines \
			<{nmcli -t connection show --active |cut -d: -f3,4
			} {|net_info|
				(net_type dev) = <={~~ $net_info *:*}
				switch $net_type (
					'cdma' {c = C}
					'802-3-ethernet' {e = E}
					'gsm' {g = G}
					'vpn' {v = V}
					'802-11-wireless' {w = W}
					{}
				)
				if {nmcli -t device show $dev \
					| grep -q '^IP4\.GATEWAY:.\+$' } \
					{i4 = 4}
				if {nmcli -t device show $dev \
					| grep -q '^IP6\.GATEWAY:.\+$' } \
					{i6 = 6}
			}
		}
		switch `{nmcli --colors no networking connectivity} (
			'portal' {n = n}
			'full' {n = N}
			{}
		)
		post_status_event
	}

	fn update_other_status_lights {
		AC_online = /sys/class/power_supply/AC/online
		access -f $AC_online && {
			if {~ `{cat $AC_online} 1} \
				{a = A} else {a = $_s}
		}
		if {hcitool con|grep -qv Connections:} \
			{b = B} else {b = $_s}
		if {xkbset q|grep -q '^Mouse-Keys = On'} \
			{m = M} else {m = $_s}
		if {!~ `{xset q|grep timeout|awk '{print $2}'} 0} \
			{z = Z} else {z = $_s}
		post_status_event
	}

	fn set_inbox_flag {|f|
		if $f {ii = I} else {ii = $_s}
		post_status_event
	}

	if $is_virt {i" = "}

	if {$enable_alerts || $enable_network_status || $enable_other_status \
			|| $enable_inbox} {
		post_status_event &
		<$trigger while true {
			switch <=read (
				network {update_network_status_lights}
				other {update_other_status_lights}
				newmail {set_inbox_flag true}
				nonewmail {set_inbox_flag false}
				{sleep 1}  # reached on $trigger EOF; abnormal
			)
		} &
		rt lights
	}
}

if $enable_network_status {
	{
		echo network  # report current state
		nmcli monitor|while true {read; echo network}
	} >$trigger &
	rt netstat
}

if $enable_other_status {
	while true {
		echo other
		sleep 3
	} >$trigger &
	rt other
}

HERE = `{cd `{dirname $ARG0}; pwd}
if $enable_inbox {
	access -f $HERE/inbox.fetchmailrc && {
		while true {
			%with-read-lines \
			<{fetchmail -c --fetchmailrc $HERE/inbox.fetchmailrc \
				--pidfile /tmp/panel-fetchmail.pid
			} {|line|
				(tm rm _) = \
					<={~~ $line *' messages ('*' seen)'*}
				if {{!~ $tm ()} && {!~ $rm ()}} {
					logger 'inbox %s %s' $tm $rm
					if {$tm :gt $rm} {
						echo newmail
					} else {
						echo nonewmail
					}
				} else {logger 'inbox %s' $line}
			}
			sleep 30
		} >$trigger &
		rt inbox
	}
}

# Draw the three panel regions
fn drawtags {|m|
	escape {|fn-return| {
		for t `{herbstclient tag_status $m >[2]/dev/null} {
			let ((f n) = `{cut --output-delimiter=' ' -c1,2- \
						<<<$t}) {
				switch <={%argify $f} (
					'.' {printf $default_attr}
					':' {printf $occupied_attr}
					'+' {printf $unfocused_attr}
					'#' {printf $selected_attr}
					'-' {printf $om_default_attr}
					'%' {printf $om_unfocused_attr}
					'!' {printf $urgent_attr}
					'' {printf ''; return}
					{printf $default_attr}
				)
				printf \ %s\n $n
			}
		}
		printf $normal_attr
	}}
}

fn drawcenter {|text|
	let (t = <={%argify $text}) {
		let (w = `{xftwidth $panel_font $t}) {
			printf '^p(_CENTER)^p(-%d)%s%s'\n \
				`($w/2) $default_attr $t
		}
	}
}

fn drawright {|text|
	let (w = `{xftwidth $panel_font <={%argify \
				`{sed 's/\^..([^)]*)//g' <<<$text}}}; \
		t = <={%argify $text}; pad = 10) {
			printf '^p(_RIGHT)^p(-%d)%s'\n `($w+$pad) $t
	}
}

# Process events
fn terminate {
	logger 'terminate'
	rm -f $pidfile
	for client `{cat $clntfile} {
		logger 'killing client %d' $client
		kill $client
	}
	rm -f $clntfile
	for df `{cat $dispfile} {
		logger 'removing display fifo %s' $df
		rm -f $df
	}
	rm -f $dispfile
	for (task pid) $taskpids {
		logger 'killing pgroup %d (%s)' $pid $task
		pkill -g $pid
	}
	rm -f $event
	rm -f $trigger
	rm -f $osdmsg
	rm -f $taskfile
	rm -f $fifofile
	exit
}

fn lights {|alert status|
	if {$enable_network_status || $enable_other_status} {
		if $enable_alerts {
			printf '%s«%s%s%s»%s«%s%s%s»%s'\n \
				$alert_marker_attr \
				$alert_indicator_attr $alert \
					$alert_marker_attr \
				$status_marker_attr \
				$status_indicator_attr $status \
					$status_marker_attr \
				$normal_attr
		} else {
			printf '%s«%s%s%s»%s'\n \
				$status_marker_attr \
				$status_indicator_attr $status \
					$status_marker_attr \
				$normal_attr
		}
	} else if $enable_alerts {
		printf '%s«%s%s%s»%s'\n \
			$alert_marker_attr \
			$alert_indicator_attr $alert $alert_marker_attr \
			$normal_attr
	}
}

fn title {herbstclient attr clients.focus.title >[2]/dev/null}

fn track {
	let (info = `` '' {/usr/bin/mpc -f $trackfmt}) {
		if {~ `{wc -l <<<$info} 1} {
			echo
		} else if {grep -qwF '[paused]' <<<$info} {
			echo
		} else {
			head -1 <<<$info|iconv -tlatin1//translit
		}
	}
}

# Run the server
logger 'starting: %s; %s; %s; %s; %s; %s; %s' \
	<={%argify `{var enable_track}} \
	<={%argify `{var enable_clock}} \
	<={%argify `{var enable_alerts}} \
	<={%argify `{var enable_network_status}} \
	<={%argify `{var enable_other_status}} \
	<={%argify `{var enable_cpubar}} \
	<={%argify `{var enable_inbox}}

let (sep; title; track; lights; at = ''; st = ''; cpubar; clock; render) {
	tags = `` \n {drawtags $monitor}
	sep = $separator_attr^'|'
	title = `title
	track = `{drawcenter `{track}}
	lights = `{lights $at $st}
	<$event while true {
		let ((ev p1 p2) = <={%split \t <=read}) {
			switch $ev (
				tag_changed {}
				tag_added {}
				tag_removed {}
				tag_renamed {}
				tag_flags {title = `title}
				focus_changed {title = $p2}
				window_title_changed {title = $p2}
				fullscreen {}
				urgent {}
				player {track = `{track}}
				inbox {set_inbox_flag $p1}
				alert {at = <={%argify $p1}; \
					lights = `{lights $at $st}}
				status {st = <={%argify $p1}; \
					lights = `{lights $at $st}}
				cpubar {cpubar = $p1}
				clock {clock = $p1}
				quit_panel {terminate}
				reload {terminate}
				{}
			)
			render = ' '$lights $cpubar $sep \
				`{echo $title|iconv -tlatin1//translit} \
				`{if $enable_track {drawcenter $track}} \
				`{if $enable_clock {drawright $clock}}
		}
		for client `{cat $dispfile} {
			let ((_ _ _ m) = <={~~ $client *-*-*-*}; tags) {
				tags = `` \n {drawtags $m}
				!~ $tags () && echo $tags $render >$client
			}
		}
	}
}
