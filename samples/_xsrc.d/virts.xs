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
	title {virsh desc $*(2) --live --config --title --new-desc $*(3 ...)}
	manage {setsid virt-manager >[2]/dev/null &}
	{throw error virts 'command?'}
	)
}
