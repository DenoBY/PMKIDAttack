#!/bin/sh

[[ -f /tmp/PMKIDAttack.progress ]] && {
  exit 0
}

touch /tmp/PMKIDAttack.progress

if [[ "$1" = "install" ]]; then
  opkg update
  wget -qO- https://raw.githubusercontent.com/n3d-b0y/hcxtools-hcxdumptool-openwrt/master/INSTALL.sh | bash -s -- -v -v

  touch /etc/config/pmkidattack
  echo "config pmkidattack 'settings'" > /etc/config/pmkidattack
  echo "config pmkidattack 'module'" >> /etc/config/pmkidattack
  echo "config pmkidattack 'attack'" >> /etc/config/pmkidattack

  uci set pmkidattack.module.installed=1
  uci commit pmkidattack.module.installed

elif [[ "$1" = "remove" ]]; then
  opkg remove hcxdumptool
  opkg remove hcxtools
  rm -rf /etc/config/pmkidattack
fi

rm /tmp/PMKIDAttack.progress
