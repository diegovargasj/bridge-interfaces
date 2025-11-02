#!/bin/sh

NAT=$1
INTERNET=$2
REDIRECTPORT=$3

if [ -z "$NAT" ] || [ -z "$INTERNET" ] || [ -z "$REDIRECTPORT" ]; then
	echo "Usage: $0 <NAT interface> <internet interface> <redirect port>"
	exit 1
fi

# Flush current rules
sudo iptables -F
sudo iptables -t nat -F
sudo iptables -X

# Define a network segment to work with
sudo ip addr add 10.0.0.1/24 dev $NAT

# Define network rules to redirect traffic
sudo iptables -A INPUT -i lo -j ACCEPT
sudo iptables -A INPUT -m state --state ESTABLISHED,RELATED -j ACCEPT

sudo iptables -A INPUT -i $NAT -p udp --dport 67:68 -j ACCEPT     # DHCP
sudo iptables -A INPUT -i $NAT -p udp --dport 53 -j ACCEPT        # DNS (UDP)
sudo iptables -A INPUT -i $NAT -p tcp --dport 53 -j ACCEPT        # DNS (TCP)

sudo iptables -A INPUT -i $NAT -p icmp -j ACCEPT

sudo iptables -t nat -A PREROUTING -i $NAT -p tcp -m tcp -j REDIRECT --to-ports $REDIRECTPORT

sudo iptables -t nat -A POSTROUTING -o $INTERNET -j MASQUERADE

sudo iptables -A FORWARD -i $NAT -o $INTERNET -p udp -j ACCEPT
sudo iptables -A FORWARD -i $INTERNET -o $NAT -p udp -m state --state ESTABLISHED,RELATED -j ACCEPT

sudo iptables -A FORWARD -i $NAT -o $INTERNET -p icmp -j ACCEPT
sudo iptables -A FORWARD -i $INTERNET -o $NAT -p icmp -m state --state ESTABLISHED,RELATED -j ACCEPT



# Configure DHCP and DNS servers
sudo dnsmasq --no-daemon --interface $NAT --dhcp-range=10.0.0.100,10.0.0.200 --log-dhcp --log-queries --bind-interfaces -C /dev/null
