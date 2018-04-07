#! /usr/bin/env xs

fn kasatoken {|kasa_user kasa_passwd|
	.d 'Aquire a fresh Kasa token'
	.a 'KASA_USERNAME KASA_PASSWORD'
	.r 'kasadevices kasaquery kasaplug kasa'
	uuid = `{uuidgen -r}
	msg = '{"method":"login","params":{"appType":"Kasa_Android",' \
		^'"cloudPassword":"%s","cloudUserName":"%s",' \
		^'"terminalUUID":"%s"}}'
	query = `` '' {printf $msg $kasa_passwd $kasa_user $uuid}
	response = `` '' {curl -s --request POST https://wap.tplinkcloud.com/ \
		--header 'Content-Type: application/json' --data $query}
	echo $response jq -r .result.token > ~/.config/k-kasa/token
}

fn kasadevices {
	.d 'Print JSON list of Kasa devices'
	.r 'kasatoken kasaquery kasaplug kasa'
	curl -s --request POST https://wap.tplinkcloud.com\?token\= \
		^`{cat ~/.config/k-kasa/token} \
		--data '{"method":"getDeviceList"}' \
		--header 'Content-Type: application/json'
}

fn kasaquery {|server device|
	.d 'Print JSON state of Kasa device'
	.a 'SERVER_URL DEVICE_ID'
	.r 'kasatoken kasadevices kasaplug kasa'
	let (msg = '{"method":"passthrough","params":{"deviceId":"%s",' \
		^'"requestData":"{\"system\":{\"get_sysinfo\":null}}}"}}') {
		curl -s --request POST $server/\?token\= \
				^`{cat ~/.config/k-kasa/token} \
			--data `` '' {printf $msg $device} \
			--header 'Content-Type: application/json'
	}
}

fn kasaplug {|server device state|
	.d 'Change state of Kasa plug; print JSON result'
	.a 'SERVER_URL DEVICE_ID 1|0'
	.r 'kasatoken kasadevices kasaquery kasa'
	let (msg = '{"method":"passthrough","params":{"deviceId":"%s",' \
		^'"requestData":"{\"system\":{\"set_relay_state\":' \
		^'{\"state\":%s}}}"}}') {
		curl -s --request POST $server/\?token\= \
				^`{cat ~/.config/k-kasa/token} \
			--data `` '' {printf $msg $device $state} \
			--header 'Content-Type: application/json' | jq .
	}
}

fn kasa {
	.d 'Control TP-Link Kasa plugs'
	.c 'system'
	.r 'kasatoken kasadevices kasaquery kasaplug'
	let (k = 'a'; m) {local (srv; did) {
		for (dev name server id) `` \n {kasadevices \
			|jq -r '.result.deviceList[]' \
				^'|.deviceName,.alias,' \
				^'.appServerUrl,.deviceId'} {
			m = $m $k "$dev"\ "$name" \
				'{(srv did) = '$server^' '$id^'}' B
		}
		%menu 'Select device' $m
		!~ $did () && %menu $srv^' '$did \
			1 Query {kasaquery $srv $did; echo} C \
			2 Turn\ On {kasaplug $srv $did 1 >/dev/null} C \
			3 Turn\ Off {kasaplug $srv $did 0 >/dev/null} C
	}}
}
