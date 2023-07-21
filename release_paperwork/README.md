# VidOS v2.00 ""

# About

VidOS is a complete single purpose linux system for x86-64 that just plays videos.
More precisely it is a bunch of pre-built components and a utility to assemble those components 
into little linux distros that just boot and play your specified videos. No compiling required!

# Changelog

# v2.00
* The second release (you can tell by the 2)
* complete rewrite of probe.sh to vobu.sh
* supports multiple videos in a playlist
* supports multiple video formats (AV1, AVC(H.264) and WEBM)
* supports multiple audio formats (AAC-LC and opus)
* supports multiple options for loading videos (ram, disk or hybrid)

# v1.00
* Initial release!
* Currently supports AV1 and opus in a matroska container
* Supports x86_64 architecture
* ISO9660 filesystem support

# System Requirements

* bash

* ffprobe

* ffmpeg

* bunzip2

* rpm2cpio

* lz4

* xorriso

you will also need wget, sed, cut and the 
usual melange of unixy command line utils,
but you prolly already have those (if you run ubuntu at least).

under a debian-esque linux distro try something like:

sudo apt-get install ffmpeg bzip2 rpm2cpio xorriso lz4


# Getting Started

To buld a VidOS distro, simply run the VidOS build utility (vobu.sh):

`./vobu.sh -d vidos_release -v funnycatvideo.mkv`

where `-d` is the path to the vidos_components directory (has the components for building VidOS distros)

and `-v` is the path/filename of your video

this will build an iso you can burn to an optical disk or block device(thumb drive)

you can use something like [etcher](ttps://etcher.balena.io/) or dd (if you are careful!)

`dd if=vidos_funnycatvideo_av1_none_ram_20xx-xx-xx.iso of=/dev/sdX bs=4M && sync`

vobu.sh also supports a ton more options outlined below
 
`VidOS build utility v1.xx`<br>
`usage: vobu -d [directory] -v [filename/dirname] -s [build style] -g [graphics drivers] -f [format]`<br>
`options:`<br>
`-h help -- print this help text`<br>
`-d directory -- path to vidos components dir`<br>
`-v filename or directory -- path to video file or directory of video files, supported video codecs: [ av1 vp8 vp9 h264 ]`<br>
`-s build style -- style of output build, one of: [ disk ram hybrid ] Default: ram`<br>
`-g graphics drivers -- binary blob graphics drivers, one or multiple of: [ amdgpu radeon i915 none all ] Default: none`<br>
`-f format  -- specific video format to use, if omitted one will be autodetected. one of: [ av1 webm avc ]`<br>

## `-h` *help* -- print this help text

prints help text

## `-d` *directory* -- path to vidos components dir

path to vidos_components directory - this is required

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

`all_the_cool_vids/`<br>
`├── sweet_skateboarding`<br>
`│   └── cool_curbgrinds.mp4`<br>
`├── rad_rimshots.webm`<br>
`├── sick_kickflips.mkv`<br>
`├── dope_dirtbikes.mkv`<br>

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

## -s *style* -- build style

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

## -g *firmware* -- graphics drivers

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


# Licenses

The buildroot configs, configuration scripts and other config files belonging to the VidOS project are 0BSD licensed. 
The compiled output of these however (which constitutes this release) is a linux distribution comprised of many packages with their own licenses.
These are contained in the license.tar.gz archive. The full source and licenses of all packages used by buildroot are contained in legal.tar.gz archive.
