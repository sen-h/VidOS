#!/bin/bash
GIT_COMMIT_HASH=$(git log -1 --format=%h)
VIDOS_VER="v2.0.0-"$GIT_COMMIT_HASH
VOBU_VER="v1.0.0-"$GIT_COMMIT_HASH
BUILDROOT_LATEST="buildroot-2023.05.1"
SYSTEMD_LATEST="v252.4"
KERNEL_LATEST="6.1.44"
KERNEL_LATEST_MAJOR=$(echo $KERNEL_LATEST | head -c 1)
SUPPORTED_FORMATS=("av1" "avc" "webm" "efi")
SUPPORTED_STYLES=("disk" "ram" "hybrid")
NAME=$VIDOS_VER

if [ ! -z $1 ]; then NAME=$1; echo $NAME; fi
if [ ! -z $2 ]; then VIDOS_VER=$2; echo $VIDOS_VER; fi
if [ ! -z $3 ]; then VOBU_VER=$3; echo $VOBU_VER; fi

mkdir -p vidos_release_$NAME/vidos_components-$VIDOS_VER
mkdir -p vidos_release_$NAME-source-and-licence-info/

pushd $BUILDROOT_LATEST

for FORMAT in "${SUPPORTED_FORMATS[@]}"; do
        make O=$FORMAT -j$(nproc) legal-info
	cp -r $FORMAT/legal-info/* ../vidos_release_$NAME-source-and-licence-info/
	cp -r $FORMAT/legal-info/manifest.csv ../vidos_release_$NAME-source-and-licence-info/$FORMAT-manifest.csv
	cp -r $FORMAT/legal-info/host-manifest.csv ../vidos_release_$NAME-source-and-licence-info/$FORMAT-host-manifest.csv
	cp -r $FORMAT/legal-info/buildroot.config ../vidos_release_$NAME-source-and-licence-info/$FORMAT-buildroot.config

	echo $FORMAT/images/vidos_release/$FORMAT"_build"/$FORMAT"_kernel"
	cp -r $FORMAT/images/vidos_release/$FORMAT"_build"/* ../vidos_release_$NAME/vidos_components-$VIDOS_VER
done

	mv ../vidos_release_$NAME-source-and-licence-info/host-sources ../vidos_release_$NAME-source-and-licence-info/combined-host-sources
	mv ../vidos_release_$NAME-source-and-licence-info/host-licenses ../vidos_release_$NAME-source-and-licence-info/combined-host-licenses
	mv ../vidos_release_$NAME-source-and-licence-info/sources ../vidos_release_$NAME-source-and-licence-info/combined-sources
	mv ../vidos_release_$NAME-source-and-licence-info/licenses ../vidos_release_$NAME-source-and-licence-info/combined-licenses
	rm ../vidos_release_$NAME-source-and-licence-info/host-manifest.csv
	rm ../vidos_release_$NAME-source-and-licence-info/manifest.csv
	rm ../vidos_release_$NAME-source-and-licence-info/buildroot.config
	rm ../vidos_release_$NAME-source-and-licence-info/legal-info.sha256

popd

scripts/prepare_release_readme.sh
cp -r vidos_x86_64/vobu.sh vidos_x86_64/test_vids LICENSE.md release_paperwork/README.md release_paperwork/*install.sh vidos_release_$NAME/
cp release_paperwork/LICENCE_README LICENCE.md vidos_release_$NAME-source-and-licence-info/

wget https://cdn.kernel.org/pub/linux/kernel/v$KERNEL_LATEST_MAJOR.x/linux-$KERNEL_LATEST.tar.xz -O vidos_release_$NAME-source-and-licence-info/linux-$KERNEL_LATEST.tar.xz
wget https://buildroot.org/downloads/$BUILDROOT_LATEST.tar.xz -O  vidos_release_$NAME-source-and-licence-info/$BUILDROOT_LATEST.tar.xz
wget https://github.com/systemd/systemd-stable/archive/refs/tags/$SYSTEMD_LATEST.tar.gz -O  vidos_release_$NAME-source-and-licence-info/systemd-stable-$SYSTEMD_LATEST.tar.gz
find vidos_release_$NAME -type f -name "rootfs.cpio.lz4" -delete
rm vidos_release_$NAME/vidos_components-$VIDOS_VER/vidos_iso9660/video/*
rm -r vidos_release_$NAME/vidos_components-$VIDOS_VER/avc_external_lib

sed -i "/^GIT_COMMIT_HASH*/d" vidos_release_$NAME/vobu.sh
sed -i "/^VOBU_VER=*/c\VOBU_VER=${VOBU_VER}" vidos_release_$NAME/vobu.sh
sed -i "/^VIDOS_COMP_VER=*/c\VIDOS_COMP_VER=${VIDOS_VER}" vidos_release_$NAME/vobu.sh

tar -I pigz -cf vidos_release_$NAME.tar.gz vidos_release_$NAME
tar -I pigz -cf legal.tar.gz vidos_release_$NAME-source-and-licence-info
