#!/bin/bash

if [ -f "/etc/f3lnet.conf" ]; then
    source /etc/f3lnet.conf
fi

# if WIFIDEV is set in .conf or globally, do nothing
# otherwise default to wlan0

: ${WIFIDEV:='wlan0'}

case $1 in
	"start")
		if grep -q F3LNET /etc/hosts ; then
			hostlist=`grep F3LNET /etc/hosts`
		else
			echo "Refresh hostlist first!"
			echo "'f3lnet.sh refresh'"
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
		ip li set $WIFIDEV down
		# batman-adv inserts an additional header of 28 bytes
		ip li set $WIFIDEV mtu 1528
		iwconfig $WIFIDEV mode ad-hoc essid {{essid}} channel {{channel}} ap {{bssid}} key off
		modprobe batman_adv
		batctl if add $WIFIDEV
		ip li set $WIFIDEV up
		ip li set bat0 up
		ip a add "$my_ip/{{subnet}}" dev bat0
	;;
	"stop")
		ip li set bat0 down
		ip li set $WIFIDEV down
		batctl if del $WIFIDEV
	;;
	"refresh")
		newhosts="`curl -s {{host_url}}`"
		if echo "$newhosts" | grep -q F3LNET ; then
			sed -i '/F3LNET$/d' /etc/hosts
			echo "$newhosts" | grep F3LNET >> /etc/hosts
			echo "Added the following hosts:"
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
