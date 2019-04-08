#!/bin/bash

export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:/sd/lib:/sd/usr/lib
export PATH=$PATH:/sd/usr/bin:/sd/usr/sbin

TIMESTAMP=`date "+[%Y-%m-%d %H:%M:%S]"`

if [[ -e /sd ]]; then
	LOGFILE="/sd/modules/PMKIDAttack/pmkidattack.log"
else
	LOGFILE="/pineapple/modules/PMKIDAttack/pmkidattack.log"
fi

function add_log {
	echo $TIMESTAMP $1 >> $LOGFILE
}

if [[ "$1" == "" ]]; then
	add_log "Argument's missing! Run script with \"dependencies.sh [install|remove]\""
	exit 1
fi

add_log "Starting dependencies installation script with argument: $1"

touch /tmp/PMKIDAttack.progress

# Let's setup some function to ALWAYS use the latest version, as it is often updated.
mkdir -p /tmp/PMKIDAttack
wget https://github.com/adde88/hcxtools-hcxdumptool-openwrt/tree/master/bin/ar71xx/packages/base -P /tmp/PMKIDAttack
HCXTOOLS=`grep -F "hcxtools_" /tmp/PMKIDAttack/base | awk {'print $5'} | awk -F'"' {'print $2'}`
HCXDUMPT=`grep -F "hcxdumptool_" /tmp/PMKIDAttack/base | awk {'print $5'} | awk -F'"' {'print $2'}`

if [[ "$1" = "install" ]]; then

	add_log "Updating opkg"

	if [[ -e /sd ]]; then
		add_log "Installing on SD"
		wget https://github.com/adde88/hcxtools-hcxdumptool-openwrt/raw/master/bin/ar71xx/packages/base/"$HCXTOOLS" -P /tmp/PMKIDAttack
		wget https://github.com/adde88/hcxtools-hcxdumptool-openwrt/raw/master/bin/ar71xx/packages/base/"$HCXDUMPT" -P /tmp/PMKIDAttack
		opkg update
		opkg -d sd install /tmp/PMKIDAttack/"$HCXTOOLS" >> $LOGFILE

		if [[ $? -ne 0 ]]; then
			add_log "ERROR: opkg -d sd install "$HCXTOOLS" failed"
			exit 1
		fi

		opkg -d sd install /tmp/PMKIDAttack/"$HCXDUMPT" >> $LOGFILE

		if [[ $? -ne 0 ]]; then
			add_log "ERROR: opkg -d sd install "$HCXDUMPT" failed"
			exit 1
		fi
	else
		add_log "Installing internal"

        opkg install /tmp/PMKIDAttack/"$HCXTOOLS"

		if [[ $? -ne 0 ]]; then
			add_log "ERROR: opkg install "$HCXTOOLS" failed"
			exit 1
		fi

		opkg install /tmp/PMKIDAttack/"$HCXDUMPT"

		if [[ $? -ne 0 ]]; then
			add_log "ERROR: opkg install "$HCXDUMPT" failed"
			exit 1
		fi
	fi

	add_log "Installation completed sucessfully!"

	touch /etc/config/pmkidattack

	echo "config pmkidattack 'settings'" > /etc/config/pmkidattack
	echo "config pmkidattack 'module'" >> /etc/config/pmkidattack
	echo "config pmkidattack 'attack'" >> /etc/config/pmkidattack

	uci set pmkidattack.module.installed=1
	uci commit pmkidattack.module.installed
fi

if [[ "$1" = "remove" ]]; then
	add_log "Removing dependencies, and the module"
	rm -rf /etc/config/pmkidattack
	opkg remove hcxtools
	opkg remove hcxdumptool
	add_log "Removal complete!"
fi

rm -rf /tmp/PMKIDAttack.progress
rm -rf /tmp/PMKIDAttack
