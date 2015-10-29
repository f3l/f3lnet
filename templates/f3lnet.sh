#!/bin/bash

if [ -f "/etc/f3lnet.conf" ]; then
    source /etc/f3lnet.conf
fi

: "${ETHDEV:='eth0'}"
: "${WIFIDEV:='wlan0'}"

handle_help() {
	echo "For $1 the following actions exist:"
	echo "  start:   Start f3lnet on $1"
	echo "  stop:    Stop $1"
}

f3lnet_help() {
	echo "F3L Net:"
	echo "  Usage: f3nlet (<service>|refresh|help) <(start|stop)>"
	echo "where service is one of"
	echo "  mesh:   BATMAN Wifi meshed network"
	echo "  lan:    LAN with f3lnet-IP"
	echo ""
	echo "  refresh:  Update hostlist"
	echo "  help:     Print this help message"
	echo ""
	handle_help "a service,"
}

fetch_hosts() {
	newhosts="$(curl -s {{host_url}})"
	if echo "$newhosts" | grep -q F3LNET ; then
		sed -i '/F3LNET$/d' /etc/hosts
		echo "$newhosts" | grep F3LNET >> /etc/hosts
		echo "Added the following hosts:"
		echo "$newhosts"
	else
		echo "HTTP request failed!"
		echo "$newhosts"
	fi
}

parse_hosts() {
	if grep -q F3LNET /etc/hosts ; then
		hostlist=$(grep F3LNET /etc/hosts)
	else
		echo "Refresh hostlist first!"
		echo "'f3lnet.sh refresh'"
		exit 1
	fi
	my_host=$(hostname | sed -e 's/\..*//')
	if echo "$hostlist" | grep -q "$my_host" ; then
			my_entry=$(echo "$hostlist" | grep "$my_host.{{tld}}")
	else
		echo "The name \"$my_host\" is not in the hostlist!"
		exit 1
	fi
	my_ip=$(echo "$my_entry" | awk '{print $1}')
}

mesh_handle() {
	case $1 in
		"start")
			parse_hosts
			ip li set "$WIFIDEV" down
			# batman-adv inserts an additional header of 28 bytes
			ip li set "$WIFIDEV" mtu 1528
			iwconfig "$WIFIDEV" mode ad-hoc essid {{essid}} channel {{channel}} ap {{bssid}} key off
			modprobe batman_adv
			batctl if add "$WIFIDEV"
			ip li set "$WIFIDEV" up
			ip li set bat0 up
			ip a add "$my_ip/{{subnet}}" dev bat0
			;;
		"stop")
			ip li set bat0 down
			ip li set "$WIFIDEV" down
			batctl if del "$WIFIDEV"
			;;
		*)
			handle_help "batman ('mesh')"
			;;
	esac
}

lan_handle() {
	case $1 in
		"start")
			parse_hosts
			ip a add "$my_ip/{{subnet}}" dev "$ETHDEV"
			;;
		"stop")
			parse_hosts
			ip a delete "$my_ip/{{subnet}}" dev "$ETHDEV"
			;;
		*)
			handle_help lan
			;;
	esac
	}

case $1 in
	"help")
		f3lnet_help
		;;
	"refresh")
		fetch_hosts
		;;
	"mesh")
		mesh_handle "$2"
		;;
	"lan")
		lan_handle "$2"
		;;
	*)
		f3lnet_help
		exit 1
	;;
esac
