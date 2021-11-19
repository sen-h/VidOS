# VidOS

Complete single purpose linux system for x86-64 that just plays videos.
More precisely it is a bunch of pre-built components and a utility to assemble those components
into little linux distros that just boot and play your specified videos
No compiling required!

# Why?

I mean, why not?
Prior startup experience has left me with a bit of an obsession with minimal linux systems and video codecs.
Also, it occurs to me that AV1 video is approximately the same bit rate as 1x CD speed (1.4 Mb/s).
One could (and I have) play a 1080P video off of a CD. 

Also, I learned after working on this project for a over a year that this isn't an original idea (go figure): [Movix](http://movix.sourceforge.net/Docs/eMoviX/countries/en/main.html)

Movix/eMovix appears to have been abandoned mid 2006, yet there still exists a plugin for it inside of [k3b](https://apps.kde.org/k3b/).

An eventual goal is to upstream this project into k3b as an official plugin.

# Theory of operation

A minimal linux system is built with alsa-lib, libdrm, mpv etc..
The entire root fileystem is then lz4 compressed and linked into the kernel binary.
Upon bootup, an init script initializes audio stuff, mounts whatever boot media was used, 
loads binary blob graphics drivers (if applicable) 
and then runs mpv with the drm option to output directly to a framebuffer. 
After the video(s) ends poweroff is called and the device shuts down.

# Supported video formats per Kernel Package

Kernel Package	|Video Container(s)			    |Supported video codec(s)|Supported audio codec	|
|---		|---					    |---		     |---			|
|vidos_avc	|matroska (.mkv) <br> MPEG-4 part 10 (.mp4) | AVC/H.264		     | AAC-LC			|
|vidos_av1	|matroska (.mkv)			    | AV1		     | opus			|
|vidos_webm	|matroska (.mkv) <br> webm (.webm)	    | vp8/vp9		     | opus			|

# Getting Started

To buld a VidOS distro, simply run the VidOS build utility (vobu.sh):

`./vobu.sh -d vidos_release -v funnycatvideo.mkv`

where `-d` is the path to the vidos_release directory (has the components for building VidOS distros)

and `-v` is the path/filename of your video

this will build an iso you can burn to an optical disk or block device(thumb drive)

vobu.sh also supports a ton more options outlined below
 
`VidOS build ultilty`<br>
`usage: vobu -d directory -v [filename/dirname] -s [build style] -f [firmware] -c [codec]`<br>
`options:`<br>
`-h help -- print this help text`<br>
`-d directory -- path to vidos resource dir`<br>
`-v filename or directory -- path to video file or directory of video files, supported video codecs: [ av1 vp8 vp9 h264 ]`<br>
`-s build style -- style of output build, one of: [ disk ram hybrid ] Default: ram`<br>
`-f firmware -- binary graphics drivers, one or multiple of:[ amdgpu radeon i915 none all ] Default: none`<br>
`-c codec -- specific video codec to use, if omitted one will be autodetected. one of: [ av1 vp8 vp9 h264 ]`<br>

## -h help -- print this help text

prints help text

## -d directory -- path to vidos resource dir

path to vidos_release directory - this is required

## -v filename or directory -- path to video file or directory of video files

provide a path to a video file like so:

`./vobu.sh -v myvid.mkv`

or mulitple video files like this:

`./vobu.sh -v myvid.mkv -v catvid.mkv -v dogvid.mkv etc...`

or a directory (and its subdirectories) full of video files like this:

`./vobu.sh -v all_the_cute_animals/`

if -c is not specified, vobu finds the first video with a codec it supports,
and then only finds videos with that same codec.

for example on multi filename arguments:

`./vobu.sh -v h264vid.mp4 -v av1vid.mkv -v differenth264vid.mp4 -v webmvid.webm`

because an H.264(AVC) encoded video was found first
(because it was specified first) the built distro will only contain h264vid.mp4
and differenth264vid.mp4

if you call -v on a directory like so:

`./vobu.sh -v all_the_cool_vids/`

vobu uses find to crawl through all of its sub directories using the same rules

so if all_the_cool_vids/ looked like this:

`all_the_cool_vids/`<br>
`├── sweet_skateboarding`<br>
`│   └── cool_curbgrinds.mp4`<br>
`├── rad_rimshots.webm`<br>
`├── sick_kickflips.mkv`<br>
`├── dope_dirtbikes.mkv`<br>

vobu will find dope_dirtbikes.mkv first 
even though it comes after cool_curbgrinds.mp4 because it is in the root dir.
and because dope_dirtbikes.mkv is encoded in av1, vobu next finds
sick_kickflips.mkv which is also encoded in av1, but ignores rad_rimshots.webm.

to get around this use -c to explicitly set the mandatory codec:

`./vobu.sh -v all_the_cool_vids/ -c h264`

vobu will only find cool_curbgrinds.mp4

or:

`./vobu.sh -v all_the_cool_vids/ -c vp8`

vobu will only find rad_rimshots.webm

bear in mind that vobu interprets both vp8 and vp9 as webm,
so if you specify either one, vobu will grab both.

so: 

`./vobu.sh -v vp9_encodedvideo.webm -c vp8`  

will work and so will:

`./vobu.sh -v vp8_encodedvideo.webm -c vp9`  

## -s *style* -- build style

the style of build vidos will output, different styles mean different
behaviours for where the videos are stored in the final image.
consequently this affects the time between powering the device on and video playback.

### ram

videos are stored in the initramfs, this means as soon as the kernel 
mounts the initramfs the video is available and playback can start.
you are only reading from the disk once at the beginning when isolinux pulls 
the kernel (bzImage) and the initramfs (rootfs.cpio.lz4) into ram. 

this is a good option for a few short, small videos. 
as more video = bigger initramfs = longer initramfs load time = longer time before playback starts.

past a certain point, mounting and reading from a disk
after boot is probably faster (depending on setup) than the time it takes to load 
a really big initramfs (rootfs.cpio.lz4) at boot.

### disk

videos are stored in a directory on disk (boot media).
This means you can store lots of big video files but you have to wait until the disk is mounted
before you can start playback.

### hybrid

this is sort of a mixture of the previous 2 options, but with a twist.

the first video in the playlist is split into 10 second chunks, and the
first chunk is stored in the initramfs, but the rest are stored on disk.

This means that the first video can start playing as soon as the kernel and initramfs is
loaded, (just like the ram option) but can be a really big file because the
rest of it is being read from disk, not ram.

all subsequent videos are stored on disk.

This is an attempt to be the "best of both worlds" approach, but a practical
speed difference between this and the ram option is highly dependent on setup
(boot media, usb host speed, processor speed etc..)
I came up with this method after learning that USB devices are detected
asyncronosly and as such don't block the boot process and can appear at any
time. This was an attempt to get around that, and yield the fastest power
button to image on glass time.
Ideally you start playing the video asap and by the time you have finshed
the first chunk the disk has been mounted and the remaining chunks are
available.
YMMV.  

## -f *firmware*

this selects linux-firmware binary graphics driver directory to package in the initramfs.

your choice will affect the final size of the initramfs and as such the total boot time.

### `amdgpu` 
for amd gpus

### `radeon` 

for radeon or some older amd gpus
### `i915` 
for some intel gpus

### `none`
doesn't install any drivers 

### `all`
installs all of them (`amdgpu`, `radeon` and `i915`)

## `-c` *codec*

this selects the codec and corresponding format so that 
vobu can select a kernel package to build your distro around.

this is autoselected by vobu by default but can be overridden by calling this option

this could come in handy if you had a whole folder full of videos in different formats,
and you wanted to make sure you grabbed a specific type  

# Bootloader

isolinux is being used beacuse I *hate* grub with a passion (also iso9660 filsystems FTW).
eventually I would love to migrate to some sort of efi boot stub situation though.

# Kernel

The kernel and its linked-in initramfs are built with absolute minimum support for everything required. 

# File System 

The video lives in a folder on the root of the iso9660 filesytem, next to the kernel and bootloader.
Previous versions simply installed the video into the initramfs,
but this yields longer boot times as the whole kernel blob gets bigger depending on the size of your video.
This also required recompilation of the kernel every time a new video is desired.
Now the kernel is a fixed size (~16MB) and it mounts the boot media automatically and plays directly off the disk.
Changing out the video is as simple as putting a new one in the video folder and rebuilding the iso. See probe.sh for more details

# building VidOS

Run 'build.sh' *video format*

video formats:

'av1' builds with support for av1 video + opus audio in an mkv container

'webm' builds with support for vp8/vp9 video + opus audio in a webm or mkv container

'avc' builds with support for H.264(AVC) video + AAC audio in a mkv or mp4 container

This will download buildroot, build a relocateable toolchain (sdk) 
and do some various setup functions as well as building an image.

you can then run 'build_release.sh' to bundle all of the releases into one directory


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
