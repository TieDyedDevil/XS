fn docker-latest {|*|
	.d 'Print IMAGE ID of most recently-created Docker image'
	.a '[-q]  # Suppress image details to stderr'
	.c 'system'
	let (id = `{docker images -q|head -1}) {
		if {!~ $* -q} {
			docker images --format '{{.ID}}'\t'{{.Repository}}' \
				^\t'{{.Tag}}'\t'{{.CreatedAt}}' \
				| grep \^$id \
				| column -t -N ID,Repository,Tag,CreatedAt \
				>[1=2]
			printf 'Labels ' >[1=2]
			docker inspect $id | jq -M '.[]|.Config|.Labels' >[1=2]
		}
		echo $id
	}
}

fn dps {|*|
	.d 'Docker ps'
	.a '[-l]  # show labels'
	.c 'system'
	let (fmt = '{{.ID}} {{.Image}} {{.Names}} {{.Command}}' \
	^' "{{.Status}}"') {
		~ $* -l && fmt = $fmt^' "{{.Labels}}"'
		docker ps --format $fmt |grep -v '^$' \
			|| echo 'No Docker containers' >[1=2]
	}
}

fn docker-run {|*|
	.d 'Run Docker image'
	.a '[docker_run-OPTIONS] IMAGE_ID'
	.c 'system'
	docker run --rm --privileged -it $*
}

fn docker-run-X {|*|
	.d 'Run Docker image with access to host X display'
	.a '[docker_run-OPTIONS] IMAGE_ID'
	.c 'system'
	docker run --rm --privileged -it -e DISPLAY \
		-v /tmp/.X11-unix:/tmp/.X11-unix \
		-v $HOME/.Xauthority:/home/galois/.Xauthority \
		--net=host --pid=host --ipc=host $*
}
