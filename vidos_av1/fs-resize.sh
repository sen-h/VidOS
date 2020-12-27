#!/bin/sh
#after initramfs is rebuilt with video and linked into the kernel,
#genimage needs to increase the size of the vfat disk image that contains it.
#this is acheived through sed magic
#while this should parse kernel sizes into the terabyte range,
#there will undoubtedly be ram/processor limitations far before then
echo "Resizing disk image..."
FS_SIZE=$(du -sh output/images/bzImage | grep -o [0-9]*[MGT]) &&
sed -i 35d board/vidos_av1/genimage-initramfs.cfg &&
sed -i "34 a \    size = $FS_SIZE" board/vidos_av1/genimage-initramfs.cfg &&
echo "Resized disk image to" $FS_SIZE

