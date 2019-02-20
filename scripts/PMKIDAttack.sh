#!/bin/sh

if [[ "$1" = "start" ]]; then
    hcxdumptool -o /tmp/$2.pcapng -i wlan1mon --filterlist=/pineapple/modules/PMKIDAttack/filter.txt --filtermode=2 --enable_status=1 &> /dev/null &
fi