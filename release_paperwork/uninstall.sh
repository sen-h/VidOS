#!/bin/sh
if [ $USER != "root" ]; then
	echo "Error: installation requires root privledges, try 'sudo ./uninstall.sh'"
	exit 1
fi
rm -r /opt/vidos
rm /usr/local/bin/vobu
echo "all done!"
