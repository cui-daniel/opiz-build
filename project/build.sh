#!/bin/bash
[ "$(id -u)" = "0" ] || exec sudo bash $0 $@

function quit() {
	code=$1
	shift
	echo "$@"
	exit $code
}

THIS=$(readlink -f "$0")
HOME=$(dirname "$THIS")
CARD=$1

cd $HOME


which pv > /dev/null || apt-get install -y pv
[ -z "$CARD" ] && quit 1 "Usage: $0 <card>"
[ -b "$CARD" ] || quit 1 "Error: card:$CARD not is block device"
mount | grep /dev/sdc && quit 1 "Errot: device is mounted"

echo "Info: write image"
cat opiz-debian-jessie-3.4.113.img.gz.?? | gzip -d | pv | dd if=/dev/stdin of=$CARD bs=1M || exit 2
echo "Info: synchronize..."
sync

echo "Info: resize partition"
echo "p:d:n:p::::w:" | tr ':' '\n' | fdisk $CARD || exit 2
e2fsck -f ${CARD}1
resize2fs ${CARD}1
sync
