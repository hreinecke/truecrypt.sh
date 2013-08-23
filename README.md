truecrypt.sh
============

Deniable filesystems with bash

These scripts implement a deniable filesystem using existing system tools
and some fancy bash scripting.

Design
======

The overall idea is to use unused blocks within an existing filesystem.
These blocks are then assembled together via device-mapper to form a
new device.
To ensure that the filesystem code ignores these blocks we're using the
_badblocks_ feature of ext2/ext3.
The _badblocks_ feature was originally implemented to allow ext2/ext3 to work
with devices with known bad blocks, as was common with older drives.
Modern drives (where _modern_ means any drive since mid-90s) do their own
internal remapping, so bad blocks were basically never reported to the OS.
Or, to be precise, _if_ you do your drive is about to die anyway, so it's
probably not worth using it.
Newer filesystems like xfs or btrfs don't even have a badblocks feature, so
that should give you some idea of the extend of current usage.

So what we're doing is to create a list of arbitrary blocknumbers from the
free blocks of an existing ext2/3 filesystem, and use this list as the
badblocks list for e2fsck.
e2fsck will then mark these blocks as _bad_, and stop using them.

Using device-mapper we can than concat all these blocks together to form a new
device, within which a new filesystem can be created.
For proper deniability it is suggested to encrypt this device.

Usage
=====

truecrypt.sh consists of two scripts, *badblocks.sh* to create the list of
bad blocks, and *truecrypt.sh* to generate the device-mapper device.

A sample usage would be:

    mke2fs <device>
    bash ./badblocks.sh <device> <size> > /tmp/badblocks.lst
    e2fsck -L /tmp/badblocks.lst <device>
    bash ./truecrypt.sh <device>

which will create two device-mapper devices, `tcrypt_orig` for the filesystem
on **<device>**, and `tcrypt` for the deniable device located within the
filesystem on **<device>**.


Then we can create a device-mapper device using these blocks.

