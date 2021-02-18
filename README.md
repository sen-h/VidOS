# VidOS
Complete single purpose linux system that just plays a video encoded in AV1 and Opus

At the present moment it is a buildroot config (based off the pc_defconfig) 
and some config files and scripts that assembles an entire os (~13MB)
as a kernel binary with an attached initramfs.

--Why?

Ok so truth be told I actually created this many moons ago with the intent of rickrolling people.

AV1 videos off the youtubes' are encoded with av1 video and opus audio.

Obviously there are some nonzero licenceing issues with that, 
which is why I opted for a more genericized version.

One could, by all accounts though, use youtube-dl to assemble something suitably appropriate.

If memory serves, the result is approximately 64-ish MB


-- Theory of operation

A minimal linux system is built with alsa-lib, libdrm, various hardware drivers, 
mpv etc..
The entire root fileystem is then lz4 compressed and linked into the kernel binary.
Upon bootup, an init script initializes audio stuff and then runs mpv with the 
drm option to output directly to a framebuffer.
after the video ends poweroff is called and the device shuts down.

-- Kernel

given that the entire root file system is attached to the kernel as an initramfs,
the kernel doesn't need to read anything from disk and so all the various
block device drivers have been turned off. The same goes for networking, HID, etc..
If we don't use it turn it off. 

-- File System 

video.mkv is copied into the /opt directory before the fileystem is compressed and
attached to the kernel. 
as such the resulting kernel binary is ~12MB + the size of the video.
in the interest of efficiency, the kernel binary is packed into a vfat file system 
tailored to its exact size. 

-- Getting Started

run ./build.sh 

this will download buildroot, build a relocateable toolchain (sdk) 
and do some various setup functions as well as building an intial image.

you can then dd that to a thumb drive 
"dd if=/path/to/buildroot/output/images/disk.img of=/dev/sdX bs=4M && sync"

VidOS ships with a test video made with ffmpeg 

"ffmpeg -f lavfi -i testsrc=d=10:s=1920x1080:r=30 -f lavfi -i sine=f=300:b=2:d=10 -ac 2 -c:a libopus -c:v libsvtav1 test_video.mkv"

but that can be replaced by passing a new video to probe.sh 
"./probe.sh mynewvideo.mkv" 

suitable videos can be made using ffmpeg and one of many suitable AV1 and 
opus encoders. 

ex: "ffmpeg -i sourcevideo.mp4 -c:a libopus -c:v libsvtav1 output.mkv"

after a new video is installed, cd into the buildroot directory and run "make" to 
rebuild.

Cheers!


-- Licence 

This work is dual licenced under 0BSD and gpl v3

use either one.

