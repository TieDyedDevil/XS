%cfn {access -w /nix} nixenv {
	.d 'Establish a nix environment'
	.c 'system'
	.r 'nix-help'
	~ $NIX_PATH () && exec sh -c '. ~/.nix-profile/etc/profile.d/nix.sh;' \
			^' export MANPATH=~/.nix-profile/share/man:; exec xs'
	true
}

%cfn {access -w /nix} nix-help {
	.d 'Show nix package manager guide'
	.c 'system'
	.r 'nixenv'
	web https://nixos.org/nix/manual/
}
