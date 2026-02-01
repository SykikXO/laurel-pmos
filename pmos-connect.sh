#!/bin/bash
# pmos-connect.sh - Auto-configure USB network for postmarketOS SSH connection

set -e

PHONE_IP="172.16.42.1"
HOST_IP="172.16.42.2"
SUBNET="/24"

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${GREEN}=== postmarketOS USB Network Setup ===${NC}"

# Find USB network interface (usually starts with enp*u* or usb*)
echo -e "${YELLOW}Looking for USB network interface...${NC}"

USB_IFACE=""
for iface in /sys/class/net/*/device/product; do
    if grep -qi "xiaomi\|android\|pmos\|postmarket\|mi a3" "$iface" 2>/dev/null; then
        USB_IFACE=$(echo "$iface" | cut -d'/' -f5)
        break
    fi
done

# Fallback: look for enp*u* pattern (typical USB network naming)
if [ -z "$USB_IFACE" ]; then
    USB_IFACE=$(ip link show | grep -oE 'enp[0-9]+s[0-9]+f[0-9]+u[0-9]+|usb[0-9]+' | head -1)
fi

if [ -z "$USB_IFACE" ]; then
    echo -e "${RED}No USB network interface found.${NC}"
    echo "Make sure:"
    echo "  1. Phone is connected via USB"
    echo "  2. Phone has booted into postmarketOS"
    echo ""
    echo "Available interfaces:"
    ip link show | grep -E "^[0-9]+" | awk '{print "  " $2}'
    exit 1
fi

echo -e "${GREEN}Found interface: ${USB_IFACE}${NC}"

# Bring interface up
echo -e "${YELLOW}Bringing up ${USB_IFACE}...${NC}"
sudo ip link set "$USB_IFACE" up

# Check if IP already assigned
if ip addr show "$USB_IFACE" | grep -q "$HOST_IP"; then
    echo -e "${GREEN}IP already configured.${NC}"
else
    echo -e "${YELLOW}Assigning IP ${HOST_IP}${SUBNET}...${NC}"
    sudo ip addr add "${HOST_IP}${SUBNET}" dev "$USB_IFACE" 2>/dev/null || true
fi

# Wait for link
echo -e "${YELLOW}Waiting for link...${NC}"
sleep 2

# Test connectivity
echo -e "${YELLOW}Testing connection to phone...${NC}"
if ping -c 1 -W 2 "$PHONE_IP" &>/dev/null; then
    echo -e "${GREEN}✓ Phone is reachable at ${PHONE_IP}${NC}"
else
    echo -e "${RED}✗ Cannot reach phone at ${PHONE_IP}${NC}"
    echo "  Trying again in 3 seconds..."
    sleep 3
    if ping -c 1 -W 2 "$PHONE_IP" &>/dev/null; then
        echo -e "${GREEN}✓ Phone is reachable at ${PHONE_IP}${NC}"
    else
        echo -e "${RED}Phone not responding. Check USB connection.${NC}"
        exit 1
    fi
fi

# Optional: Set up NAT for internet access
read -p "Enable internet sharing to phone? (y/N): " enable_nat
if [[ "$enable_nat" =~ ^[Yy]$ ]]; then
    echo -e "${YELLOW}Setting up NAT...${NC}"
    
    # Find outbound interface (wifi or ethernet)
    OUTBOUND=$(ip route | grep default | awk '{print $5}' | head -1)
    
    if [ -n "$OUTBOUND" ]; then
        sudo sysctl -q net.ipv4.ip_forward=1
        sudo iptables -t nat -C POSTROUTING -s 172.16.42.0/24 -o "$OUTBOUND" -j MASQUERADE 2>/dev/null || \
            sudo iptables -t nat -A POSTROUTING -s 172.16.42.0/24 -o "$OUTBOUND" -j MASQUERADE
        echo -e "${GREEN}✓ NAT enabled via ${OUTBOUND}${NC}"
        echo ""
        echo -e "${YELLOW}On the phone, run:${NC}"
        echo "  doas ip route add default via ${HOST_IP}"
        echo "  echo 'nameserver 8.8.8.8' | doas tee /etc/resolv.conf"
    else
        echo -e "${RED}No outbound interface found.${NC}"
    fi
fi

echo ""
echo -e "${GREEN}=== Ready! ===${NC}"
echo -e "Connect with: ${GREEN}ssh sykik@${PHONE_IP}${NC}"
echo ""

# Optionally connect directly
read -p "Connect now via SSH? (Y/n): " do_ssh
if [[ ! "$do_ssh" =~ ^[Nn]$ ]]; then
    ssh "sykik@${PHONE_IP}"
fi
