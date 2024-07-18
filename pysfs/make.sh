#!/usr/bin/env bash

./cli.py new -i sdcard.img
./cli.py cp -s "/mnt/d/vgm/01 Ghostbusters Main Theme.vgm" -d sfs://ghostbust.vgm -i sdcard.img
./cli.py cp -s "/mnt/d/vgm/05SilentNight.vgm" -d sfs://slientnight.vgm -i sdcard.img
./cli.py cp -s "/mnt/d/vgm/03TheChristmasSong.vgm" -d sfs://xmassong.vgm -i sdcard.img
./cli.py cp -s "/mnt/d/vgm/06 Can-Can (Infernal Galop, Offenbach).vgm" -d sfs://cancan.vgm -i sdcard.img
./cli.py cp -s "/mnt/d/vgm/06JingleBells.vgm" -d sfs://jinglebells.vgm -i sdcard.img
./cli.py cp -s "/mnt/d/vgm/moonlightsonata.vgm" -d sfs://moonsanata.vgm -i sdcard.img
./cli.py cp -s "/mnt/d/vgm/01WeWishYouaMerryChristmas.vgm" -d sfs://merryxmas.vgm -i sdcard.img
./cli.py cp -s "/mnt/d/vgm/08FrostytheSnowman.vgm" -d sfs://frosty.vgm -i sdcard.img
./cli.py cp -s "/mnt/d/vgm/07TheFirstNoel.vgm" -d sfs://firstnoel.vgm -i sdcard.img

cd ../apps
for i in conway echo f18a_test mon vdp_c vgm wozmon_ram; do cd $i; make; cd ../; done
cd ../pysfs

./cli.py cp -s ../apps/echo/build/echo.raw -d sfs://echo.bin -i sdcard.img
./cli.py cp -s ../apps/mon/build/mon.raw -d sfs://mon.bin -i sdcard.img
./cli.py cp -s ../apps/vgm/build/vgm.raw -d sfs://vgmplayer.bin -i sdcard.img
./cli.py cp -s ../apps/conway/build/conway.raw -d sfs://conway.bin -i sdcard.img
./cli.py cp -s ../apps/f18a_test/build/f18a.raw -d sfs://f18atest.bin -i sdcard.img
./cli.py cp -s ../apps/vdp_c/build/vdp_c.raw -d sfs://vdp_c.bin -i sdcard.img
./cli.py cp -s ../apps/wozmon_ram/build/monitor.raw -d sfs://wozmon_ram.bin -i sdcard.img

