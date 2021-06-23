# VidOS

Complete single purpose linux system that just plays a video encoded in AV1 and Opus.
At the present moment it is a buildroot config (based very loosely off the pc_defconfig)
and some config files and scripts that assembles an entire os and hybrid iso (~38MB)
as a kernel binary with an attached initramfs, bootloader and the video itself. 

# Why?

I mean, why not?
Prior startup experience has left me with a bit of an obsession with minimal linux systems and video codecs.
Also, it occurs to me that AV1 video is approximately the same bit rate as 1x CD speed (1.4 Mb/s).
One could (and I have) play a 1080P video off of a CD. 

Also, I just recently learned that this is not an original idea (go figure): [Movix](http://movix.sourceforge.net/Docs/eMoviX/countries/en/main.html)
Movix/eMovix appears to have been abandoned mid 2006, yet there still exists a plugin for it inside of [k3b](https://apps.kde.org/k3b/).
An eventual goal is to upstream this project into k3b as an official plugin.

# Theory of operation

A minimal linux system is built with alsa-lib, libdrm, various hardware drivers, 
mpv etc..
The entire root fileystem is then lz4 compressed and linked into the kernel binary.
Upon bootup, an init script initializes audio stuff, mounts whatever boot media was used and then runs mpv with the drm option to output directly to a framebuffer.
After the video ends poweroff is called and the device shuts down.

# Bootloader

isolinux is being used beacuse I *hate* grub with a passion (also iso9660 filsystems FTW).
eventually I would love to migrate to some sort of efi boot stub situation though.

# Kernel

The kernel and its linked-in initramfs are with absolute minimum support for everything required. 
Unfortunately it has ballooned in size (from ~12MB to ~38MB) now that graphics firmware (the linux-firmware package) has been included.


# File System 

The video lives in a folder on the root of the iso9660 filesytem, next to the kernel and bootloader.
Previous versions simply installed the video into the initramfs,
but this yields longer boot times as the whole kernel blob gets bigger depending on the size of your video.
This also required recompilation of the kernel every time a new video is desired.
Now the kernel is a fixed size (~38MB) and it mounts the boot media automatically and plays directly off the disk.
Changing out the video is as simple as putting a new one in the video folder and rebuilding the iso. See probe.sh for more details

# Getting Started

Run ./build.sh 

This will download buildroot, build a relocateable toolchain (sdk) 
and do some various setup functions as well as building an image.

you can then dd that to a thumb drive or optical disk:

`dd if=/path/to/buildroot/output/images/output.iso of=/dev/sdX bs=4M && sync`

VidOS ships with a test video made with ffmpeg:

`ffmpeg -f lavfi -i testsrc=d=10:s=1920x1080:r=30 -f lavfi -i sine=f=300:b=2:d=10 -ac 2 -c:a libopus -c:v libsvtav1 test_video.mkv`

but that can be replaced by passing a new video to probe.sh 

`./probe.sh mynewvideo.mkv`

suitable videos can be made using ffmpeg and one of many suitable AV1 and 
opus encoders. 

`ffmpeg -i sourcevideo.mp4 -c:a libopus -c:v libsvtav1 output.mkv`

Cheers!


# Testing/development

Develpment is done on a Wyse Rx0L thin client over its serial port.
This negates the need for HID and virtio drivers.

In general, the approach is to keep things as simple and minimal as possible.
This is to avoid an excessive kernel size and prevent it from being used for nefarious purposes.

Eventually I will kick myself hard enough to get a proper PXE server running, instead of imaging thumb drives.

# To do

* make isolinux quieter (or silent)

* figure out efi bootstub stuff

* more codec support

* support for a playlist of mulitple videos instead of just one


# Licence 

This work is licenced under 0BSD
