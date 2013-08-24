truecrypt.sh
============

Deniable filesystems with bash

These scripts implement a deniable filesystem
(https://en.wikipedia.org/wiki/Plausible_deniability) using existing
system tools and some fancy bash scripting, the stress being on
*existing* as in the sense that using common tools already present on a
common Linux system without the need to develop anything new.

Design
======

The idea is to employ otherwise unused blocks within an existing
filesystem. These blocks are then assembled together via device-mapper
to form a new block device. To ensure that the filesystem code ignores
these blocks we're using the _badblocks_ feature of ext2/ext3.

The _badblocks_ feature was originally implemented to allow ext2/ext3
to work with devices with known bad blocks, as was common with older
drives. Modern drives (where _modern_ means any drive since mid-90s)
do their own internal remapping, so bad blocks were basically never
reported to the OS. Or, to be precise, _if_ they are, your drive is
_really_ about to die anyway, so it's probably not worth using it to
begin with.

Newer filesystems like xfs or btrfs don't even have a badblocks feature,
so that should give you some idea of the extent of current usage.

What we're initially going to create is a list of arbitrary block
numbers from the free blocks of an existing ext2/3 filesystem, and use
this list as the bad blocks list for e2fsck. e2fsck will then mark these
blocks as _bad_, and stop using them.

Using device-mapper we can then concatenate all these blocks together to
form a new block device, within which a new filesystem can be created.
In addition, for plausible deniability it is suggested to encrypt this
device.

Usage
=====

truecrypt.sh consists of two scripts, *badblocks.sh* to create the list of
bad blocks, and *truecrypt.sh* to generate the device-mapper device.

A sample usage would be:

    mke2fs <device>
    bash ./badblocks.sh <device> <size> > /tmp/badblocks.lst
    e2fsck -L /tmp/badblocks.lst <device>
    bash ./truecrypt.sh <device>

which will create two device-mapper devices, `tcrypt_orig` for the
filesystem on `<device>`, and `tcrypt` for the deniable device located
within the filesystem on `<device>`.

Then we can create a device-mapper device using these blocks.
