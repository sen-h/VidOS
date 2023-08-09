# VidOS

Complete single purpose linux system for x86-64 that just plays videos.
More precisely it is a bunch of pre-built components and a utility to assemble those components
into little linux distros that just boot and play your specified videos.
No compiling required!

# Why?

Well, here are some possible use cases:

* Digital Signage(think Video Ads in malls, Airport Terminal displays, menu boards in restaurants etc.)
* Education (Museum exhibits, art galleries, expo booths)

But honestly why not?
Prior startup experience has left me with a bit of an obsession with minimal linux systems and video codecs.
Also, it occurs to me that  *perceptually good* FHD AV1 video is approximately the same bit rate as 1x CD speed (1.4 Mb/s).
One could (and I have) "stream" a 1080P video off of a CD. 

Also, I learned after working on this project for a over a year that this isn't an original idea (go figure): [Movix](http://movix.sourceforge.net/Docs/eMoviX/countries/en/main.html)

Movix/eMovix appears to have been abandoned mid 2006, yet there still exists a plugin for it inside of [k3b](https://apps.kde.org/k3b/).

An eventual goal is to upstream this project into k3b as an official plugin.

# Theory of operation

A minimal linux system is built with alsa-lib, libdrm, mpv etc..
The entire root fileystem is then lz4 compressed and linked into the kernel binary.
Upon bootup, an init script initializes audio stuff, loads the video(s) 
loads binary blob graphics drivers (if applicable) 
and then runs mpv with the drm option to output directly to a framebuffer. 
After the video(s) ends poweroff is called and the device shuts down.

# Supported video formats per Kernel Package

Kernel Package	|Video Container(s)			    |Supported video codec(s)|Supported audio codec	|
|---		|--					    |---			|---			|
|vidos_avc	|matroska (.mkv) <br> MPEG-4 part 10 (.mp4) | AVC/H.264			| AAC-LC		|
|vidos_av1	|matroska (.mkv) <br> MPEG-4 part 10 (.mp4) <br> webm (.webm) | AV1	| opus			|
|vidos_webm	|matroska (.mkv) <br> MPEG-4 part 10 (.mp4) <br> webm (.webm) | vp8/vp9 | opus			|

# Getting Started

To buld a VidOS distro, simply run the VidOS build utility (vobu.sh):

`./vobu.sh -v funnycatvideo.mkv`

where `-v` is the path/filename of a video, or a directory/folder full of videos

this will build an iso you can burn to an optical disk or block device(thumb drive)

you can use something like [etcher](https://etcher.balena.io/) or dd (if you are careful!)

`dd if=vidos_funnycatvideo_av1_none_ram_20xx-xx-xx.iso of=/dev/sdX bs=4M && sync`

or test it out in qemu:

`qemu-system-x86_64 -cpu host --enable-kvm -m 500 -soundhw ac97 -vga cirrus vidos_funnycatvideo_av1_none_ram_20xx-xx-xx.iso`


vobu.sh also supports a ton more options outlined below
``` 
VidOS build utility v1.4.x
usage: vobu -d [directory] -v [filename/dirname] -b [build style] -g [graphics drivers] -f [format] -r [remove codecs] -l [bootloader/manager]
-m [mpv options] -p [playback options] -o [output iso name]
options:
-h help -- print this help text
-d directory -- path to vidos components dir, Default paths: /tmp, /opt, ./
-v video filename or directory -- path to video file or directory of video files, supported video codecs: [ av1 vp8 vp9 h264 ]
-b build style -- style of output build, one of: [ disk ram hybrid ] Default: ram
-g graphics drivers -- binary blob graphics drivers, one or multiple of: [ amdgpu radeon i915 none all ] Default: none
-f format  -- specific video format to use, if omitted one will be autodetected. one of: [ av1 webm avc ]
-r remove external codecs -- removes/disables OpenH264 and fdk-aac codecs, OpenH264 Video Codec provided by Cisco Systems, Inc.
-l bootloader/manager for firmware -- select bootloader depending on machine firmware. one of: [ efi bios both ] Default: bios
-m mpv options -- extra options to pass to mpv, see: https://mpv.io/manual/stable/#options
-p playback count -- how many times to play the video or video files: [ -1 to inf ] Default: 1
-o output iso name -- specify a name for the output iso, Defaults to: 'vidos_$VIDEO_$FORMAT_$GRAPHICS_DRIVERS_$BUILD_STYLE_$BOOTLOADER_YYYY-MM-DD.iso'
```
## `-h` *help* -- print this help text

prints help text

## `-d` *directory* -- path to vidos components dir

An explicit path to the vidos_components directory.

If unspecified vobu will try to use its working copy in /tmp
but if it can't find that, it will look for a copy it can move into /tmp.

First it checks /opt, and then it searches the current directory.

If it still can't find a copy, the path
to one must be specified with -d "path/to/vidos_components"

It will then copy that into /tmp where it can be used.

Because of this, subsequent runs of vobu will not need the
vidos_components dir specified,
at least until the copy in /tmp gets deleted :P

It should also be noted that specifiying a path will
always install a new copy in /tmp, which will of
course replace the old copy (if one exists).

This is useful when debugging/developing to ensure you are
always working with a fresh copy.

## `-v` *filename* or *directory* -- path to video file or directory of video files

provide a path to a video file like so:

`./vobu.sh -v myvid.mkv`

or mulitple video files like this:

`./vobu.sh -v myvid.mkv -v catvid.mkv -v dogvid.mkv etc...`

or a directory (and its subdirectories) full of video files like this:

`./vobu.sh -v all_the_cute_animals/`

if -f is not specified, vobu finds the first video with a format it supports,
and then only finds videos with that same format.

for example on multi filename arguments:

`./vobu.sh -v h264vid.mp4 -v av1vid.mkv -v differenth264vid.mp4 -v webmvid.webm`

because an H.264(AVC) encoded video was found first
(because it was specified first) the built distro will only contain h264vid.mp4
and differenth264vid.mp4

if you call -v on a directory like so:

`./vobu.sh -v all_the_cool_vids/`

vobu uses [find](https://linux.die.net/man/1/find) to crawl through all of its sub directories using the same rules

so if all_the_cool_vids/ looked like this:
```
all_the_cool_vids/
├── sweet_skateboarding
│   └── cool_curbgrinds.mp4
├── rad_rimshots.webm
├── sick_kickflips.mkv
├── dope_dirtbikes.mkv
```
vobu will find dope_dirtbikes.mkv first 
even though it comes after cool_curbgrinds.mp4 because it is in the root dir.
and because dope_dirtbikes.mkv is encoded in av1, vobu next finds
sick_kickflips.mkv which is also encoded in av1, but ignores rad_rimshots.webm.

to get around this use -f to explicitly set the mandatory format/codec:

`./vobu.sh -v all_the_cool_vids/ -f avc`

vobu will only find cool_curbgrinds.mp4

or:

`./vobu.sh -v all_the_cool_vids/ -f webm`

vobu will only find rad_rimshots.webm

## `-b` *build style* -- where/how the video(s) are stored.

the style of build vidos will output, different styles mean different
behaviours for where the videos are stored in the final image.
consequently this affects the time between powering the device on and video playback.

### `ram`

videos are stored in the initramfs, this means as soon as the kernel 
mounts the initramfs the video is available and playback can start.
you are only reading from the disk once at the beginning when isolinux pulls 
the kernel (bzImage) and the initramfs (rootfs.cpio.lz4) into ram. 

this is a good option for a few short, small videos. 
as more video = bigger initramfs = longer initramfs load time = longer time before playback starts.

past a certain point, mounting and reading from a disk
after boot is probably faster (depending on setup) than the time it takes to load 
a really big initramfs (rootfs.cpio.lz4) at boot.

### `disk`

Videos are stored in a directory on disk (boot media).
This means you can store lots of big video files but you have to wait until the disk is mounted
before you can start playback.

### `hybrid`

This is sort of a mixture of the previous 2 options, but with a twist.

The first video in the playlist is split into 10 second chunks, and the
first chunk is stored in the initramfs, but the rest are stored on disk.

This means that the first video can start playing as soon as the kernel and initramfs is
loaded, (just like the ram option) but it can be a really big file because the
rest of it is being read from disk, not ram.

all subsequent videos are stored on disk.

This is an attempt to be the "best of both worlds" approach, but a practical
speed difference between this and the ram option is highly dependent on setup
(boot media, usb host speed, processor speed etc..)
I came up with this method after learning that USB devices are detected
asyncronosly and as such don't block the boot process and can appear at any
time. This was an attempt to get around that, and yield the fastest power
button to image on glass time.
The idea being you start playing the video asap and by the time you have finshed
the first chunk the disk has been mounted and the remaining chunks are
available.
YMMV.

## `-g` *firmware* -- graphics drivers

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

## `-f` *format*

This selects the video codec and corresponding format so that 
vobu can select a kernel package to build your distro around.

It's autoselected by vobu by default but can be overridden by calling this option.

this could come in handy if you had a whole folder full of videos in different formats,
and you wanted to make sure you grabbed a specific type.

### `avc`

selects videos in AVC format ( H.264/AVC video and AAC audio in an mp4 or matroska container)

### `av1`

selects videos in AV1 format ( AV1 video and Opus audio in an mp4, webm or matroska container)

### `webm`

selects videos in WEBM format (VP8 or VP9 video and Opus audio in an mp4, webm or matroska container)

## `-r` *remove external codecs*

removes/disables OpenH264 and fdk-aac codecs, this is required for licencing reasons.

## `-l` *bootloader/manager for firmware*

selects bootloader/boot manager the install in the final image, this is dependent on what type of firmware
(colloqiually referred to as "The BIOS") is on the target machine.

### `bios`

installs isolinux and kernel package + initramfs on the disk for machines with traditional bios type firmware,
images can be burnt to optical media or block devices.

### `efi`

installs systemd-boot and kernel package + initramfs in an ESP on the disk for machines with efi compliant firmware,
images can be burnt to optical media or block devices.

Secure boot is not supported and MUST be disabled.

### `both`

installs isolinux and kernel package + initramfs on the disk and also installs systemd-boot and kernel package + initramfs in an ESP.

because the same stuff is duplicated in two places, the resulting final image will be bigger, sometimes by 2X.

for instance, given an image built with the `ram` style and a 10MB video + 20MB kernel package, the final image will be 60MB.

however, for an image built with `disk` style the video is not packed in the initramfs so it's not duplicated.
therefore the final image will be 50MB ((20MB kernel package)*2 + 10MB video)

It should however (theoretically at least) run on any pc regardless of the firmware implementation.

## `-m` *mpv options* -- extra options for mpv

passes additional options to mpv, see the mpv docs for info: https://mpv.io/manual/stable/#options

It should be noted that all options specfied here are appended to the mpv arguments in the particular S03Video* script

so for something like:

`vobu.sh -v all_the_cool_vids/ -m --shuffle`

the line in the S03Video script would be:

`mpv -vo=drm --playlist=/path/to/playlist.txt --shuffle`

## `-p` *playback count*

this is *essentially* a macro for the `-m` option, it appends the `--loop-playlist` option with the passed value, defaulting to `1`

this is done after what (if any) options were passed with `-m`

So for something like:

`vobu.sh -v all_the_cool_vids/ -p 1 -m --shuffle`

or

`vobu.sh -v all_the_cool_vids/ -m --shuffle`

the line in the S03Video script would be:

`mpv -vo=drm --playlist=/path/to/playlist.txt --shuffle --loop-playlist=1`

## `-o` *output iso name*

specify the output filename/path, the `.iso` suffix is automagically appended

# Bootloader

isolinux is being used for machines with traditional "bios" firmware,
and systemd-boot is used for machines with efi compliant firmware.

while the kernel images are built with the efi stub and as such could be executed
directly by the efi firmware without a second stage,
systemd-boot is needed in order to load the external initramfs from the ESP.

# Kernel

The kernel and its linked-in initramfs are built with absolute minimum support for everything required. 

# File System 

There is a standard unixy file system in the initramfs that's linked into the kernel.(bzImage)
The second initramfs(rootfs.cpio.lz4), which lives on disk, 
contains a few folders that are overlayed onto the first initramfs. 
What's inside of the second initramfs is determined by the `-g`, `-v` and `-b` options
The third filesystem is the iso9660 file system(disk) that constitiutes the boot media.
Along with containing the kernel package and second initramfs, it may also contain videos depending on the `-b` option.

# building VidOS components from source

 `./build.sh` *video format*

This will download buildroot and do some various setup functions as well as building the 
relevent kernal packages and a test image.

you can then run 'build_release.sh' to bundle all of the releases into one directory

afterwords cd into the release dir and run vobu as usual:

`./vobu.sh -v funnycatvideo.mkv`

you can then dd that to a thumb drive or optical disk:

`dd if=/path/to/buildroot/output/images/output.iso of=/dev/sdX bs=4M && sync`

VidOS ships with test videos made with ffmpeg:
### AV1
`ffmpeg -f lavfi -i "testsrc=d=10:s=1920x1080:r=30" -filter_complex drawtext='fontfile=/usr/share/fonts/truetype/freefont/FreeSans.ttf:fontcolor=white:fontsize=140:text='AV1'' -f lavfi -i sine=f=300:b=2:d=10 -ac 2 -c:a libopus -c:v libsvtav1 -pix_fmt yuv420p av1_video.mkv`

### WEBM
`ffmpeg -f lavfi -i "testsrc=d=10:s=1920x1080:r=30" -filter_complex drawtext='fontfile=/usr/share/fonts/truetype/freefont/FreeSans.ttf:fontcolor=white:fontsize=140:text='WEBM'' -f lavfi -i sine=f=300:b=2:d=10 -ac 2 -c:a libopus -c:v libvpx-vp9 -pix_fmt yuv420p webm_video.webm`

### AVC
`ffmpeg -f lavfi -i "testsrc=d=10:s=1920x1080:r=30" -filter_complex drawtext='fontfile=/usr/share/fonts/truetype/freefont/FreeSans.ttf:fontcolor=white:fontsize=140:text='AVC'' -f lavfi -i sine=f=300:b=2:d=10 -ac 2 -c:a libfdk_aac -c:v libopenh264 -pix_fmt yuv420p avc_video.mp4`

Cheers!

# Testing/development

~~Develpment is done on a Wyse Rx0L thin client over its serial port.~~
~~This negates the need for HID and virtio drivers.~~
New _virt kernel config has Cirrus vga support, and works pretty well thru qemu.
something like:

`qemu-system-x86_64 -cpu host --enable-kvm -m 500 -soundhw ac97 -vga cirrus -cdrom path/to/iso.iso`

works pretty well.

In general, the approach is to keep things as simple and minimal as possible.
This is to avoid an excessive kernel size and prevent it from being used for nefarious purposes.

~~Eventually I will kick myself hard enough to get a proper PXE server running, instead of imaging thumb drives.~~ *got this working a while ago actually*

# Notes
# To do

~~* make isolinux quieter (or silent)~~ *implemented with optional patch*

~~* figure out efi bootstub stuff~~ *done*

~~* more codec support~~ *supports the 3 major web codecs*

~~* support for a playlist of mulitple videos instead of just one~~ *implemented*

~~* looping video support~~ *done*

* support ARM64/rpi4 *in process*

* more hw platform support

# Licence 

This work is licenced under 0BSD
