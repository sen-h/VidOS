#!/bin/sh
BUILDROOT_LATEST=buildroot-2021.08

cp 0018-quiet-isolinux-test.patch $BUILDROOT_LATEST/boot/syslinux/

echo "installed syslinux patch!"
