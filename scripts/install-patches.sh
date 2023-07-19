#!/bin/sh
BUILDROOT_LATEST=buildroot-2023.05.1

cp patches/0018-quiet-isolinux-test.patch $BUILDROOT_LATEST/boot/syslinux/

echo "installed syslinux patch!"
