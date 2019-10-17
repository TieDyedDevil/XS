fn mamel {
	.d 'List installed MAME games'
	.c 'game'
	ls /usr/share/mame/roms|sed 's/\.zip$//'|column -c `{tput cols}
}
