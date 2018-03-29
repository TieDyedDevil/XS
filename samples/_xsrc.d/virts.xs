fn virts {|*|
	.d 'VM utility'
	.a 'list'
	.a 'active'
	.a 'inactive'
	.a 'start VM'
	.a 'view VM'
	.a 'ifaddr VM'
	.a 'info VM'
	.a 'shutdown VM'
	.a 'reboot VM'
	.a 'reset VM'
	.a 'destroy VM'
	.a 'dumpxml VM  # to stdout'
	.a 'define XMLFILE'
	.a 'undefine VM'
	.a 'clone VM'
	.a 'title VM TITLE...'
	.a 'manage'
	.c 'system'
	switch <={%argify $*(1)} (
	list {virsh list --title --all}
	active {virsh list --title}
	inactive {virsh list --title --inactive}
	start {virsh start $*(2)}
	view {setsid virt-viewer $*(2) >[2]/dev/null &}
	ifaddr {virsh domifaddr $*(2)}
	info {virsh dominfo $*(2)}
	shutdown {virsh shutdown $*(2)}
	reboot {virsh reboot $*(2)}
	reset {virsh reset $*(2)}
	destroy {virsh destroy $*(2)}
	dumpxml {virsh dumpxml $*(2)}
	define {virsh define $*(2)}
	undefine {virsh undefine $*(2) --remove-all-storage --nvram}
	clone {virt-clone --original $*(2) --auto-clone}
	title {virsh desc $*(2) --live --config --title --new-desc $*(3 ...)}
	manage {setsid virt-manager >[2]/dev/null &}
	{throw error virts 'command?'}
	)
}
