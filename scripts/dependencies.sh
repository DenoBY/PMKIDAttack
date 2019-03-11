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
	add_log "Argument to script missing! Run with \"dependencies.sh [install|remove]\""
	exit 1
fi

add_log "Starting dependencies script with argument: $1"

touch /tmp/PMKIDAttack.progress

if [[ "$1" = "install" ]]; then

	add_log "Updating opkg"

	if [[ -e /sd ]]; then
		add_log "Installing on sd"

	    opkg --dest sd install /pineapple/modules/PMKIDAttack/scripts/ipk/hcxtools_5.1.3-1_ar71xx.ipk >> $LOGFILE

		if [[ $? -ne 0 ]]; then
			add_log "ERROR: opkg --dest sd install hcxtools_5.1.3-1_ar71xx.ipk failed"
			exit 1
		fi

		opkg --dest sd install /pineapple/modules/PMKIDAttack/scripts/ipk/hcxdumptool_5.1.3-1_ar71xx.ipk >> $LOGFILE

		if [[ $? -ne 0 ]]; then
			add_log "ERROR: opkg --dest sd install hcxdumptool_5.1.3-1_ar71xx.ipk failed"
			exit 1
		fi
	else
		add_log "Installing on disk"

        opkg install /pineapple/modules/PMKIDAttack/scripts/ipk/hcxtools_5.1.3-1_ar71xx.ipk

		if [[ $? -ne 0 ]]; then
			add_log "ERROR: opkg install hcxtools_5.1.3-1_ar71xx.ipk failed"
			exit 1
		fi

		opkg install /pineapple/modules/PMKIDAttack/scripts/ipk/hcxdumptool_5.1.3-1_ar71xx.ipk

		if [[ $? -ne 0 ]]; then
			add_log "ERROR: opkg install hcxdumptool_5.1.3-1_ar71xx.ipk failed"
			exit 1
		fi
	fi

	add_log "Installation complete!"

	touch /etc/config/pmkidattack

	echo "config pmkidattack 'settings'" > /etc/config/pmkidattack
	echo "config pmkidattack 'module'" >> /etc/config/pmkidattack
	echo "config pmkidattack 'attack'" >> /etc/config/pmkidattack

	uci set pmkidattack.module.installed=1
	uci commit pmkidattack.module.installed
fi

if [[ "$1" = "remove" ]]; then
	add_log "Removing a module"

    rm -rf /etc/config/PMKIDAttack

	opkg remove hcxtools
	opkg remove hcxdumptool

	add_log "Removing complete!"
fi

rm /tmp/PMKIDAttack.progress
