#!/bin/sh

NAT=$1
INTERNET=$2
REDIRECTPORT=$3

if [ -z "$NAT" ] || [ -z "$INTERNET" ] || [ -z "$REDIRECTPORT" ]; then
	echo "Usage: $0 <NAT interface> <internet interface> <redirect port>"
	exit 1
fi

sudo ip addr add 10.0.0.1/24 dev $NAT

sudo iptables -A INPUT -i $NAT -j ACCEPT
sudo iptables -t nat -A PREROUTING -i $NAT -p tcp -m tcp -j REDIRECT --to-ports $REDIRECTPORT
sudo iptables -t nat -A POSTROUTING -o $INTERNET -j MASQUERADE

sudo dnsmasq --no-daemon --interface $NAT --dhcp-range=10.0.0.100,10.0.0.200 --log-dhcp --log-queries --bind-interfaces -C /dev/null
