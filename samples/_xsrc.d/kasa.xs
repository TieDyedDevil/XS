
fn kasatoken {|kasa_user kasa_passwd|
	.d 'Aquire a fresh Kasa token'
	.a 'KASA_USERNAME KASA_PASSWORD'
	.r 'kasadevices kasaquery kasaplug kasa'
	.c 'iot'
	~ $kasa_passwd () && throw error kasatoken 'user passwd'
	uuid = `{uuidgen -r}
	msg = '{"method":"login","params":{"appType":"Kasa_Android",' \
		^'"cloudPassword":"%s","cloudUserName":"%s",' \
		^'"terminalUUID":"%s"}}'
	query = `` '' {printf $msg $kasa_passwd $kasa_user $uuid}
	response = `` '' {curl -s --request POST https://wap.tplinkcloud.com/ \
		--header 'Content-Type: application/json' --data $query}
	access -d ~/.config/k-kasa || mkdir -p ~/.config/k-kasa
	echo $response | jq -r .result.token > ~/.config/k-kasa/token
}

fn kasadevices {
	.d 'Print JSON list of Kasa devices'
	.r 'kasatoken kasaquery kasaplug kasa'
	.c 'iot'
	access -f ~/.config/k-kasa/token || throw error kasadevices 'no token'
	curl -s --request POST https://wap.tplinkcloud.com\?token\= \
		^`{cat ~/.config/k-kasa/token} \
		--data '{"method":"getDeviceList"}' \
		--header 'Content-Type: application/json'
}

fn @kasa-sysinfo {|json|
	jq .result.responseData.system.get_sysinfo
}

fn @kasa-unquote {|json|
	sed 's/\\"/"/g'|sed 's/"{/{/'|sed 's/}"/}/'
}

fn kasaquery {|server device|
	.d 'Print JSON state of Kasa device'
	.a 'SERVER_URL DEVICE_ID'
	.r 'kasatoken kasadevices kasaplug kasa'
	.c 'iot'
	~ $device () && throw error kasaquery 'server device'
	let (msg = '{"method":"passthrough","params":{"deviceId":"%s",' \
		^'"requestData":"{\"system\":{\"get_sysinfo\":null}}}"}}') {
		curl -s --request POST $server/\?token\= \
					^`{cat ~/.config/k-kasa/token} \
				--data `` '' {printf $msg $device} \
				--header 'Content-Type: application/json' \
			| @kasa-unquote
	}
}

fn kasaplug {|server device state|
	.d 'Change state of Kasa plug; print JSON result'
	.a 'SERVER_URL DEVICE_ID 1|0'
	.r 'kasatoken kasadevices kasaquery kasa'
	.c 'iot'
	~ $state () && throw error kasaplug 'server device state'
	let (msg = '{"method":"passthrough","params":{"deviceId":"%s",' \
		^'"requestData":"{\"system\":{\"set_relay_state\":' \
		^'{\"state\":%s}}}"}}') {
		curl -s --request POST $server/\?token\= \
					^`{cat ~/.config/k-kasa/token} \
				--data `` '' {printf $msg $device $state} \
				--header 'Content-Type: application/json' \
			| @kasa-unquote
	}
}

fn kasa {
	.d 'Control TP-Link Kasa plugs'
	.r 'kasatoken kasadevices kasaquery kasaplug'
	.c 'iot'
	access -f ~/.config/k-kasa/token || throw error kasa 'no token'
	let (k = a b c d e f g h i j k l m n o p q r s t u v w x y z; i) {
	local (srv; did; m) {
		m =
		i = 1
		for (dev name server id) `` \n {kasadevices \
				|jq -r '.result.deviceList[]' \
					^'|.deviceName,.alias,' \
					^'.appServerUrl,.deviceId'} {
			m = $m $k($i) "$dev"\ "$name" \
				'{(srv did) = '$server^' '$id^'}' B
			i = `($i+1)
		}
		m = $m . Exit {m =} B
		while {!~ $m ()} {
		%menu 'Select device' $m
		!~ $did () && %menu $srv^' '$did \
			0 Another\ device {srv =; did =} B \
			1 Query {kasaquery $srv $did \
				| @kasa-sysinfo \
				| jq '{relay_state,on_time,active_mode}'} C \
			2 Turn\ On {kasaplug $srv $did 1|jq .result} C \
			3 Turn\ Off {kasaplug $srv $did 0|jq .result} C \
			. Exit {m =} B
		}
	}}
}
