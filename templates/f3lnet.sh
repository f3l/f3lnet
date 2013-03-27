#!/bin/bash

case $1 in
	"start")
		echo "Starting..."
		if grep -q F3LNET /etc/hosts ; then
			hostlist=`grep F3LNET /etc/hosts`
		else
			echo "Refresh hostlist first!"
			exit 1
		fi
		my_host=`hostname | sed -e 's/\..*//'`
		if echo "$hostlist" | grep -q "$my_host" ; then
			my_entry=`echo "$hostlist" | grep "$my_host.{{tld}}"`
		else
			echo "The name \"$my_host\" is not in the hostlist!"
			exit 1
		fi
		my_ip=`echo $my_entry | awk '{print $1}'`
		echo "Found entry: \"$my_host\" => \"$my_ip\""
		set -x
		ip li set wlan0 down
		# batman-adv inserts an additional header of 28 bytes
		ip li set wlan0 mtu 1528
		iwconfig wlan0 mode ad-hoc essid {{essid}} channel {{channel}} ap {{bssid}}
		modprobe batman_adv
		batctl if add wlan0
		ip li set wlan0 up
		ip li set bat0 up
		ip a add "$my_ip/24" dev bat0
		set +x
	;;
	"stop")
		echo "Stopping..."
		ip li set bat0 down
		ip li set wlan0 down
		batctl if del wlan0
	;;
	"refresh")
		newhosts="`curl -s {{host_url}}`"
		if echo "$newhosts" | grep -q F3LNET ; then
			sed -i '/F3LNET$/d' /etc/hosts
			echo "$newhosts" | grep F3LNET >> /etc/hosts
			echo "Added this hosts:"
			echo "$newhosts"
		else
			echo "HTTP request failed!"
			echo "$newhosts"
		fi
	;;
	*)
		echo "F3L Net:"
		echo "  start:   Start BATMAN"
		echo "  stop:    Stop BATMAN"
		echo "  refresh: Update hostlist"
	;;
esac
