# Raspberry Pi image including FOG server

The image contains all FOG dependencies and assets, and can be used fully offline.

FOG is automatically installed during the first boot.

Default Linux and FOG user is `fog` and password is `password`.

Compatible with Raspberry Pi 3, 4 and 5.

Download the `.img.xz` image from [Releases](../../releases).

Deploy the image using [Raspberry Pi Imager](https://github.com/raspberrypi/rpi-imager) or from command line:
```sh
sudo umount --quiet /dev/mmcblk0*
xzcat rpi-fog-v1.5.10.1754.img.xz | sudo dd of=/dev/mmcblk0 status=progress conv=fsync bs=64M
```
