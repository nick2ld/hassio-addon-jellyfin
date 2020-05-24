#!/usr/bin/env bashio

# SIGTERM-handler this funciton will be executed when the container receives the SIGTERM signal (when stopping)
term_handler(){
	echo "Stopping..."
	ifdown wlan0
	ip link set wlan0 down
	ip addr flush dev wlan0
	exit 0
}

# Setup signal handlers
trap 'term_handler' SIGTERM

echo "Starting..."

echo "Set nmcli managed no"
nmcli dev set wlan0 managed no

CONFIG_PATH=/data/options.json

SSID=$(bashio::config 'ssid')
WPA_PASSPHRASE=$(bashio::config 'wpa_passphrase')
CHANNEL=$(bashio::config 'channel')
ADDRESS=$(bashio::config 'address')
NETMASK=$(bashio::config 'netmask')
BROADCAST=$(bashio::config 'broadcast')
declare stmac
declare stip
stmac='1'
stip='1'
# Enforces required env variables
required_vars=(SSID WPA_PASSPHRASE CHANNEL ADDRESS NETMASK BROADCAST)
for required_var in "${required_vars[@]}"; do
    if [[ -z ${!required_var} ]]; then
        error=1
        echo >&2 "Error: $required_var env variable not set."
    fi
done

for i in $(bashio::config 'statics|keys'); do
	if ! bashio::config.has_value "statics[${i}].mac"; then
		stmac=$(bashio::config "statics[${i}].mac")
		echo "мак - $stmac"
	fi
	if ! bashio::config.has_value "statics[${i}].ip"; then
		stip=$(bashio::config "statics[${i}].ip")
		echo "ip - $stmac"
	fi
		echo "Add static IP $stip for $stmac..."
		echo "dhcp-host=$stmac,$stip"$'\n' >> /etc/dnsmasq.conf
done

#if [[ -n $error ]]; then
#    exit 1
#fi

# Setup hostapd.conf
echo "Setup hostapd ..."
echo "ssid=$SSID"$'\n' >> /hostapd.conf
echo "wpa_passphrase=$WPA_PASSPHRASE"$'\n' >> /hostapd.conf
echo "channel=$CHANNEL"$'\n' >> /hostapd.conf

# Setup interface
echo "Setup interface ..."

#ip link set wlan0 down
#ip addr flush dev wlan0
#ip addr add ${IP_ADDRESS}/24 dev wlan0
#ip link set wlan0 up

echo "address $ADDRESS"$'\n' >> /etc/network/interfaces
echo "netmask $NETMASK"$'\n' >> /etc/network/interfaces
echo "broadcast $BROADCAST"$'\n' >> /etc/network/interfaces

ifdown wlan0
ifup wlan0

echo "Starting HostAP daemon ..."

hostapd -d /hostapd.conf & wait ${!}
dnsmasq
