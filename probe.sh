#!/bin/sh
VID_CODEC=$(./ffprobe -hide_banner -loglevel 0 -show_streams $1 | grep -w codec_name | sed -n 1p)
AUD_CODEC=$(./ffprobe -hide_banner -loglevel 0 -show_streams $1 | grep -w codec_name | sed -n 2p)

if [ $VID_CODEC = "codec_name=av1" ]; then
  echo "video passed"
  cp $1 buildroot-2020.11/board/vidos_av1/rootfs-overlay/opt/video.mkv
  echo "installed $1 as new video"
elif [ $VID_CODEC != "codec_name=av1" ]; then
  echo "Error: Video is not encoded in AV1, please try again!"
fi

if [ $AUD_CODEC = "codec_name=opus" ]; then
  echo "audio passed"
elif [ $VID_CODEC != "codec_name=opus" ]; then
  echo "Warning: audio is not encoded in opus, and will not play back!"
fi
