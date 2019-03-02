#!/bin/sh

export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:/sd/lib:/sd/usr/lib
export PATH=$PATH:/sd/usr/bin:/sd/usr/sbin

TIMESTAMP=`date "+[%Y-%m-%d %H:%M:%S]"`
LOGFILE="/var/log/pmkidattack.log"

if [[ "$1" == "" ]]; then
	echo "$TIMESTAMP Argument to script missing! Run with \"dependencies.sh [install|remove]\"" >> $LOGFILE
	exit 1
fi

echo "$TIMESTAMP Starting dependencies script with argument:" $1 >> $LOGFILE

touch /tmp/PMKIDAttack.progress

if [[ "$1" = "install" ]]; then

	echo "$TIMESTAMP Updating opkg" >> $LOGFILE
	
	if [[ -e /sd ]]; then
		echo "$TIMESTAMP Installing on sd" >> $LOGFILE

	    opkg --dest sd install /pineapple/modules/PMKIDAttack/scripts/ipk/hcxtools_5.1.3-1_ar71xx.ipk >> $LOGFILE

		if [[ $? -ne 0 ]]; then
			echo "$TIMESTAMP ERROR: opkg --dest sd install hcxtools_5.1.3-1_ar71xx.ipk failed" >> $LOGFILE
			exit 1
		fi

		opkg --dest sd install /pineapple/modules/PMKIDAttack/scripts/ipk/hcxdumptool_5.1.3-1_ar71xx.ipk >> $LOGFILE

		if [[ $? -ne 0 ]]; then
			echo "$TIMESTAMP ERROR: opkg --dest sd install hcxdumptool_5.1.3-1_ar71xx.ipk failed" >> $LOGFILE
			exit 1
		fi
	else
		echo "$TIMESTAMP Installing on disk" >> $LOGFILE

        opkg install /pineapple/modules/PMKIDAttack/scripts/ipk/hcxtools_5.1.3-1_ar71xx.ipk

		if [[ $? -ne 0 ]]; then
			echo "$TIMESTAMP ERROR: opkg install hcxtools_5.1.3-1_ar71xx.ipk failed" >> $LOGFILE
			exit 1
		fi

		opkg install /pineapple/modules/PMKIDAttack/scripts/ipk/hcxdumptool_5.1.3-1_ar71xx.ipk

		if [[ $? -ne 0 ]]; then
			echo "$TIMESTAMP ERROR: opkg install hcxdumptool_5.1.3-1_ar71xx.ipk failed" >> $LOGFILE
			exit 1
		fi
	fi

	echo "$TIMESTAMP Installation complete!" >> $LOGFILE
	
	touch /etc/config/pmkidattack

	echo "config pmkidattack 'settings'" > /etc/config/pmkidattack
	echo "config pmkidattack 'module'" >> /etc/config/pmkidattack
	echo "config pmkidattack 'attack'" >> /etc/config/pmkidattack

	uci set pmkidattack.module.installed=1
	uci commit pmkidattack.module.installed
fi

if [[ "$1" = "remove" ]]; then
	echo "$TIMESTAMP Removing PMKIDAttack module" >> $LOGFILE

    rm -rf /etc/config/PMKIDAttack
	
	opkg remove hcxtools 
	opkg remove hcxdumptool

	echo "$TIMESTAMP Removing complete!" >> $LOGFILE
fi

rm /tmp/PMKIDAttack.progress
