#!/bin/sh
VIDOS_VER="2.00"
if [ $USER != "root" ]; then
	echo "Error: installation requires root privledges, try 'sudo ./install.sh'"
	exit 1
fi
mkdir -p /opt/vidos
cp -r vidos_components-v$VIDOS_VER /opt/vidos/
cp vobu.sh /usr/local/bin/vobu
echo "all done!"
