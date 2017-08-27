#!/bin/bash
[ "$(id -u)" = "0" ] || exec sudo bash $0 $@

function _quit() {
	code=$1
	shift
	echo "$@"
	exit $code
}

function _write() {
	which pv > /dev/null || apt-get install -y pv
	echo "Info: write image"
	cat opiz-debian-jessie-3.4.113.img.gz.?? | gzip -d | pv | dd if=/dev/stdin of=$CARD bs=1M || exit 2
	echo "Info: synchronize..."
	sync
}

function _expand() {
	echo "Info: resize partition"
	echo "p:d:n:p::::w:" | tr ':' '\n' | fdisk $CARD || exit 2
	e2fsck -f ${CARD}1
	resize2fs ${CARD}1
	sync
}

MESSAGE_1="Usage: $THIS <card> [mode:write|expand|all]"
MESSAGE_2="Error: card:$CARD not is block device"
MESSAGE_3="Errot: device is mounted"

THIS=$(readlink -f "$0")
HOME=$(dirname "$THIS")
CARD=$1
MODE=$2
cd $HOME

[ -z "$MODE" ] && MODE=all
[ -z "$CARD" ] && _quit 1 $MESSAGE_1
[ -b "$CARD" ] || _quit 1 $MESSAGE_2
mount | grep $CARD && _quit 1 $MESSAGE_3

case "$MODE" in
	write)
		_write
	;;
	expand)
		_expand
	;;
	all)
		_write
		_expand
	;;
	*)
		echo $MESSAGE_1
	;;
esac
