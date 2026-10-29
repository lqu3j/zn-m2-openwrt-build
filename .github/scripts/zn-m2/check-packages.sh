#!/bin/bash
set -euo pipefail

MODE="${1:?Usage: check-packages.sh config|manifest FILE}"
INPUT="${2:?Usage: check-packages.sh config|manifest FILE}"
[ -f "$INPUT" ] || { echo "ERROR: package list not found: $INPUT" >&2; exit 1; }

case "$MODE" in
  config)
    PACKAGES=$(awk -F= '/^CONFIG_PACKAGE_.*=y$/ {sub(/^CONFIG_PACKAGE_/, "", $1); print $1}' "$INPUT")
    ;;
  manifest)
    PACKAGES=$(awk -F ' - ' '{print $1}' "$INPUT")
    ;;
  *) echo "ERROR: unknown package list format: $MODE" >&2; exit 1 ;;
esac

FORBIDDEN='^(gecoosac|luci-app-gecoosac|luci-i18n-gecoosac-.*|luci-app-(passwall[0-9]*|lucky|nps)|luci-i18n-(passwall[0-9]*|lucky|nps)-.*|lucky|npc|sing-box|haproxy|hysteria|xray-.*|v2ray-(geoip|geosite|plugin)|chinadns-ng|dns2socks|dns2tcp|ipt2socks|microsocks|simple-obfs-client|ssocks|tcping|shadowsocks.*|trojan.*|naiveproxy|tuic-client|shadow-tls|geoview|kmod-usb.*)$'
if UNEXPECTED=$(grep -E "$FORBIDDEN" <<< "$PACKAGES"); then
  printf 'ERROR: excluded packages in %s:\n%s\n' "$INPUT" "$UNEXPECTED" >&2
  exit 1
fi

for package in openvpn-openssl luci-app-openvpn kmod-tun ip-full kmod-inet-diag kmod-netlink-diag ca-bundle firewall iptables kmod-ipt-nat dnsmasq-full busybox tcpdump ss ethtool bind-dig mtr-nojson iputils-arping; do
  if ! grep -Fxq "$package" <<< "$PACKAGES"; then
    echo "ERROR: required package missing from $INPUT: $package" >&2
    exit 1
  fi
done

if [[ "$MODE" == config ]]; then
  BUSYBOX_PREFIX=CONFIG_BUSYBOX_DEFAULT_
  if grep -Fxq 'CONFIG_BUSYBOX_CUSTOM=y' "$INPUT"; then
    BUSYBOX_PREFIX=CONFIG_BUSYBOX_CONFIG_
  fi
  for applet in NSLOOKUP NETSTAT FEATURE_NETSTAT_PRG PING PING6 TRACEROUTE TRACEROUTE6 NC; do
    if ! grep -Fxq "${BUSYBOX_PREFIX}${applet}=y" "$INPUT"; then
      echo "ERROR: required BusyBox option missing from $INPUT: $applet" >&2
      exit 1
    fi
  done
fi
echo "Package selection verified: $INPUT"
