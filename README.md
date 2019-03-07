## PMKIDAttack

The module automates PMKID attack

![alt text](https://i.ibb.co/GdDrdKd/PMKIDAttack.png)

**Device:** Tetra / NANO

[![Demo video](https://i.ibb.co/wMf1BGg/PMKIDAttack-You-Tube.png)](https://youtu.be/AU2kAd3PUz8)

**Official topics for discussions:**
```
https://codeby.net/threads/6-wifi-pineapple-pmkidattack.66709
https://forums.hak5.org/topic/45365-module-pmkidattack/
```

**Module installation for Tetra:**
```
opkg update && opkg install git git-http
cd /pineapple/modules/
git clone https://github.com/n3d-b0y/PMKIDAttack.git PMKIDAttack
chmod +x -R /pineapple/modules/PMKIDAttack/scripts
```

**Module installation for NANO:**
```
# This module requires sd card
opkg update && opkg --dest sd install install git git-http
cd /sd/modules/
git clone https://github.com/n3d-b0y/PMKIDAttack.git PMKIDAttack
chmod +x -R /sd/modules/PMKIDAttack/scripts
```
