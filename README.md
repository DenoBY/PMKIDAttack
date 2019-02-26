## PMKIDAttack [hcxdumptools baked-in]

* This fork comes included with the hcxtools required to run the PMKID attack. 
* This method avoids network dependencies for acquiring opkg binaries from another repo.

* You can verify the authenticity of packages by comparing md5sums yourself.

The module automates PMKID attack

![alt text](https://i.ibb.co/GdDrdKd/PMKIDAttack.png)

**Device:** Tetra

**Official topics for discussions:**
```
https://codeby.net/threads/6-wifi-pineapple-pmkidattack.66709
https://forums.hak5.org/topic/45365-module-pmkidattack/
```

[![Watch the video](https://i.ibb.co/wMf1BGg/PMKIDAttack-You-Tube.png)](https://youtu.be/AU2kAd3PUz8)

**Install module:**

```
opkg update && opkg install git git-http
cd /pineapple/modules/
git clone https://github.com/n3d-b0y/PMKIDAttack.git PMKIDAttack
chmod +x -R /pineapple/modules/PMKIDAttack/scripts
```
