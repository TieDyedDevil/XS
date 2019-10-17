fn virts {|*|
	.d 'VM utility'
	.a 'list'
	.a 'active'
	.a 'inactive'
	.a 'start VM'
	.a 'view VM'
	.a 'use VM  # start (if shutoff) and view'
	.a 'ifaddr VM'
	.a 'info VM'
	.a 'blockdevs VM'
	.a 'stats VM'
	.a 'shutdown VM'
	.a 'reboot VM'
	.a 'reset VM'
	.a 'destroy VM'
	.a 'dumpxml VM [FILE]  # or stdout'
	.a 'define XMLFILE'
	.a 'undefine VM  # ... and its storage'
	.a 'clone VM [NEW_NAME...]  # ... and its storage'
	.a 'title VM TITLE...'
	.a 'desc VM DESCRIPTION...'
	.a 'pool-list'
	.a 'vol-list POOL'
	.a 'vol-info POOL VOL'
	.a 'vol-grow POOL VOL NEW_SIZE  # ... in GiB'
	.a 'vol-dumpxml POOL VOL [FILE]  # or stdout'
	.a 'vol-create POOL XMLFILE'
	.a 'vol-create-as POOL NAME.EXT CAPACITY'
	.a 'vol-delete POOL VOLUME'
	.a 'vol-clone POOL SRC_VOLUME DST_VOLUME'
	.a 'manage'
	.a 'edit VM'
	.a 'rename VM NEW_NAME...'
	.a 'setfacl ISO  # enable qemu access to ISO under ~'
	.a 'space'
	.c 'system'
	let (fn-rh = {tail -n+3|head -n-1|tee /dev/stderr \
			|[2]{~ `{wc -l} 0 && echo 'No virts' >[1=2]}}) {
		switch <={%argify $*(1)} (
		list {virsh list --all|rh; true}
		active {virsh list|rh; true}
		inactive {virsh list --inactive|rh; true}
		start {virsh start $*(2)}
		view {setsid virt-viewer $*(2) >[2]/dev/null &}
		use {~ $*(2) `{virsh list --name --state-shutoff} \
			&& virsh start $*(2); setsid virt-viewer $*(2) \
							>[2]/dev/null &; true}
		ifaddr {virsh domifaddr $*(2)}
		info {virsh dominfo $*(2); virsh desc --title $*(2); \
			virsh desc $*(2)}
		blockdevs {virsh domblklist $*(2)|rh}
		stats {virsh domstats --cpu-total --interface --block $*(2) \
			|less -FX}
		shutdown {virsh shutdown $*(2)}
		reboot {virsh reboot $*(2)}
		reset {virsh reset $*(2)}
		destroy {virsh destroy $*(2)}
		dumpxml {virsh dumpxml $*(2) | {%redir-file-or-stdout $*(3)}}
		define {virsh define $*(2)}
		undefine {!~ $*(2) *-base || %confirm n Remove ...-base \
			&& virsh undefine $*(2) --storage <={%flatten , \
				`` \n {virsh domblklist $*(2) | tail -n-3 \
				|awk '{print $2}' | grep -v -e '^-\?$' \
				|grep -v -e '\.iso$'}} --nvram; \
			true}
		clone {virt-clone --original $*(2) --auto-clone; \
			virsh desc $*(2)^-clone --config --title '';
			virsh desc $*(2)^-clone --config --new-desc '';
			~ $*(3) () || virsh domrename $*(2)^-clone \
						<={%argify $*(3 ...)}}
		title {virsh desc $*(2) --config --title $*(3 ...)}
		desc {virsh desc $*(2) --config --new-desc $*(3 ...)}
		pool-list {virsh pool-list --all|rh}
		vol-list {virsh vol-list $*(2)|rh}
		vol-info {virsh vol-info --pool $*(2 3)|rh}
		vol-grow {virsh vol-resize --pool $(2 3) $(4)^GiB}
		vol-dumpxml {virsh vol-dumpxml --pool $*(2 3) \
					| {%redir-file-or-stdout $*(4)}}
		vol-create {virsh vol-create $*(2 3)}
		vol-create-as {virsh vol-create-as $*(2) `{basename $*(3)} \
			$*(4) --format <={%ext $*(3)}}
		vol-delete {virsh vol-delete --pool $*(2 3)}
		vol-clone {virsh vol-clone --pool $(2 3 4)}
		manage {setsid virt-manager >[2]/dev/null &}
		edit {virsh edit $(2)}
		rename {virsh domrename $*(2) <={%argify $*(3 ...)}}
		setfacl {sudo setfacl -m u:qemu:rx $*(2); \
			let (p = `pwd^/^`` \n {dirname $*(2)}) {
				while {!~ $p $HOME && !~ $p ()} {
					sudo setfacl -m u:qemu:x $p
					p = `` \n {dirname $p}
				}
			}
			sudo setfacl -m u:qemu:x $HOME}
		space {sudo du -h /var/lib/libvirt/images}
		{throw error virts 'command?'}
		)
	}
}

fn virt-resize-X {|*|
	.d 'Resize virtual display for X'
	.a 'x y'
	.c 'system'
	%only-X
	systemd-detect-virt -q || throw error virt-resize-X 'only virt'
	if {!~ $#* 2} {
		.usage resize
	} else {
		let (ms; (x y) = $*; mon = Virtual-0) {
			ms = `{cvt $x $y|cut -sd" -f3-11|sed 's/  / /g' \
							|cut -d' ' -f2-11}
			let (mode = $x^x^$y) {
				if {!{xrandr|grep -q '^ \+'^$mode}} {
					xrandr --newmode $mode $ms
					xrandr --addmode $mon $mode
				}
				xrandr --output $mon --mode $mode
				wallgen -c
			}
		}
	}
}
