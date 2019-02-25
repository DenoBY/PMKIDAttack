#!/bin/sh
#2019 - trashbo4t

export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:/sd/lib:/sd/usr/lib
export PATH=$PATH:/sd/usr/bin:/sd/usr/sbin

LOGFILE="/var/log/pmkidattack.log"
VOID=""

echo "----------------------------------------------" >> $LOGFILE
echo "New PMKIDAttack Log Entry: " `date` >> $LOGFILE
echo "----------------------------------------------" >> $LOGFILE

if [ "$1" = "$VOID" ]; then
	echo "argument to script missing! run with \"dependencies.sh <install>/<remove>/<force <option>>\"" >> $LOGFILE
	exit 1
fi

echo "starting dependencies script with argument: " $1 $2 >> $LOGFILE

ARG=$VOID

if [ "$1" = "force" ]; then
	rm /tmp/PMKIDAttack.progress
	ARG=$2
else
	ARG=$1
fi	

if [ "$ARG" = "$VOID" ]; then
	echo "ERROR: Force argument to script missing! run with \"dependencies.sh <force <install>/<remove>>\"" >> $LOGFILE
	exit 1
fi

[[ -f /tmp/PMKIDAttack.progress ]] && {
	echo "[$ARG] ERROR: dependencies script exited early on -f /tmp/PMKIDAttack.progess check" >> $LOGFILE
	echo "try running with \"dependencies.sh force\" <install>/<remove>" >> $LOGFILE
	exit 0
}

echo "[$ARG] Creating hcx files and /tmp/PMKIDAttack.progress file" >> $LOGFILE

touch /tmp/PMKIDAttack.progress
touch /usr/lib/opkg/info/hcxdumptool.control
touch /usr/lib/opkg/info/hcxdumptool.list
touch /usr/lib/opkg/info/hcxtools.control
touch /usr/lib/opkg/info/hcxtools.list

if [ "$ARG" = "install" ]; then
	echo "[$ARG] Installing dependencies" >> $LOGFILE

	echo "[$ARG] Updating opkg" >> $LOGFILE

	opkg update >> $LOGFILE
	
	if [ -e /sd ]; then
		echo "[$ARG] Installing on sd" >> $LOGFILE

	        opkg --dest sd install /pineapple/modules/PMKIDAttack/scripts/ipk/hcxtools_5.1.0-1_ar71xx.ipk >> $LOGFILE 
		if [ $? -ne 0 ]; then
			echo "[$ARG] ERROR: opkg --dest sd install /pineapple/modules/PMKIDAttack/scripts/ipk/hcxtools_5.1.0-1_ar71xx.ipk failed" >> $LOGFILE
			exit 1
		fi

		opkg --dest sd install /pineapple/modules/PMKIDAttack/scripts/ipk/hcxdumptool_5.1.0-1_ar71xx.ipk >> $LOGFILE
		if [ $? -ne 0 ]; then
			echo "[$ARG] ERROR: opkg --dest sd install /pineapple/modules/PMKIDAttack/scripts/ipk/hcxdumptool_5.1.0-1_ar71xx.ipk failed" >> $LOGFILE
			exit 1
		fi

		opkg --dest sd install /pineapple/modules/PMKIDAttack/scripts/ipk/hcxdumptool_5.1.0-1_mips_24kc_musl.ipk >> $LOGFILE
		if [ $? -ne 0 ]; then
			echo "[$ARG] ERROR: opkg --dest sd install /pineapple/modules/PMKIDAttack/scripts/ipk/hcxdumptool_5.1.0-1_mips_24kc_musl.ipk failed" >> $LOGFILE
			exit 1
		fi
	else
		echo "[$ARG] Installing on disk" >> $LOGFILE

	        # Tetra install / general install.
	        opkg install /pineapple/modules/PMKIDAttack/scripts/ipk/hcxtools_5.1.0-1_ar71xx.ipk 
		if [ $? -ne 0 ]; then
			echo "[$ARG] ERROR: opkg install /pineapple/modules/PMKIDAttack/scripts/ipk/hcxtools_5.1.0-1_ar71xx.ipk failed" >> $LOGFILE
			exit 1
		fi

		opkg install /pineapple/modules/PMKIDAttack/scripts/ipk/hcxdumptool_5.1.0-1_ar71xx.ipk 
		if [ $? -ne 0 ]; then
			echo "[$ARG] ERROR: opkg install /pineapple/modules/PMKIDAttack/scripts/ipk/hcxdumptool_5.1.0-1_ar71xx.ipk failed" >> $LOGFILE
			exit 1
		fi

		opkg install /pineapple/modules/PMKIDAttack/scripts/ipk/hcxdumptool_5.1.0-1_mips_24kc_musl.ipk
		if [ $? -ne 0 ]; then
			echo "[$ARG] ERROR: opkg install /pineapple/modules/PMKIDAttack/scripts/ipk/hcxdumptool_5.1.0-1_mips_24kc_musl.ipk failed" >> $LOGFILE
			exit 1
		fi
	fi

	echo "[$ARG] Installation complete!" >> $LOGFILE
	
	touch /etc/config/pmkidattack
	echo "config pmkidattack 'settings'" > /etc/config/pmkidattack
	echo "config pmkidattack 'module'" >> /etc/config/pmkidattack
	echo "config pmkidattack 'attack'" >> /etc/config/pmkidattack
	
	# edit for PMKIDAttack module
	uci set pmkidattack.module.installed=1
	uci commit pmkidattack.module.installed

	#uci set PMKID.module.installed=1
	#uci commit PMKID.module.installed
fi

if [ "$ARG" = "remove" ]; then
	echo "[$ARG] Removing pmkidattack module" >> $LOGFILE

        rm -rf /etc/config/PMKIDAttack
	
	opkg remove hcxtools 
	opkg remove hcxdumptool     
fi

echo "[$ARG] Removing /tmp/PMKIDAttack.progress file" >> $LOGFILE

rm /tmp/PMKIDAttack.progress

echo "[$ARG] Complete!" >> $LOGFILE
