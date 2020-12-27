# VidOS
Complete single purpose linux system that just plays a video encoded in AV1 and Opus

At the present moment it is a buidroot config (based off the pc_defconfig) that assembles an entire os (~13MB)
as a kernel binary with an attached initramfs.


-- Getting Started

run ./build.sh 

this will download buildroot, build a reloacatble toolchain (sdk) and do some various setup functions as well as building an intial image.

you can then dd that to a thumb drive ( dd =if /path/to/buildroot/output/images =of /dev/sdX bs=4M)

VidOS ships with a test video made with ffmpeg  (ffmpeg -f lavfi -i testsrc=d=10:s=1920x1080:r=30 -f lavfi -i sine=f=300:b=2:d=10 -ac 2 -c:a libopus -c:v libsvtav1 video.mkv)

but that can be replaced by passing a new video to probe.sh (./probe.sh mynewvideo.mkv) 

sutable videos can be made using ffmpeg and one of many suitable AV1 and opus encoders. ex: (ffmpeg -i sourcevideo.mp4 -c:a libopus -c:v libsvtav1 output.mkv)

after a new video is installed, cd into the buildroot dir and run make to rebuild.

Cheers!


--licence 

This work is dual licenced under 0BSD and gpl v3

use whatever.

