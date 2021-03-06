#!/bin/sh
LOG="logger -p user.info -t mdev-mount"
WARN="logger -p user.warn -t mdev-mount"

MOUNTBASE=/media
MOUNTPOINT="$MOUNTBASE/$MDEV"
ROOTDEV=$(readlink /dev/root)

# do not add or remove root device again...
[ "$ROOTDEV" = "$MDEV" ] && exit 0

if [ -e /tmp/.nomdevmount ]; then
	LOG "no action on $MDEV -- /tmp/.nomdevmount exists"
	exit 0
fi

case "$ACTION" in
	add)
		# do not mount kernel partitions
		for i in 2 4 6 8; do
			if [ ${MDEV:$((${#MDEV}-1)):1} -eq $i ]; then
				$LOG "[$ACTION] /dev/$MDEV is a kernel partition - not mounting."
				exit 0
			fi
		done
		# TODO: check for partitions
		if grep -q "/dev/$MDEV" /proc/mounts; then
			$LOG "/dev/$MDEV already mounted - not mounting again"
			exit 0
		fi
		$LOG "[$ACTION] mounting /dev/$MDEV to $MOUNTPOINT"
		# remove old mountpoint symlinks we might have for this device
		rm -f $MOUNTPOINT
		mkdir -p $MOUNTPOINT
		mount -t auto /dev/$MDEV $MOUNTPOINT 2>&1 >/dev/null
		RET=$?
		if [ $RET != 0 ]; then
			$WARN "mount   /dev/$MDEV $MOUNTPOINT failed with $RET"
			$WARN "        $OUT1"
			rmdir $MOUNTPOINT
		fi
		;;
	remove)
		$LOG "[$ACTION] unmounting $MOUNTBASE/$MDEV"
		grep -q "^/dev/$MDEV " /proc/mounts || exit 0 # not mounted...
		umount -lf $MOUNTBASE/$MDEV
		RET=$?
		if [ $RET = 0 ]; then
			rmdir $MOUNTPOINT
		else
			$WARN "umount $MOUNTBASE/$MDEV failed with $RET"
		fi
		;;
esac
