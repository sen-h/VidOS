#!/bin/sh
#download and unpack latest ffmpeg release
FFMPEG_VERSION=ffmpeg-4.4
wget -c https://ffmpeg.org/releases/$FFMPEG_VERSION.tar.xz &&
tar -xf $FFMPEG_VERSION.tar.xz &&
rm $FFMPEG_VERSION.tar.xz &&
cd $FFMPEG_VERSION && mkdir build && cd build
#build only ffprobe
../configure --disable-everything --disable-ffmpeg --disable-ffplay --enable-demuxer=matroska,mov --enable-protocol=file --enable-static &&
make -j$(nproc) &&
mv ffprobe ../../ &&
cd  ../../ &&
rm -r $FFMPEG_VERSION

