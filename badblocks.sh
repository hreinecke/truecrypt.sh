#!/bin/bash
#
# badblocks.sh
#
# Generate list of bad blocks from existing free blocks in an
# ext2/ext3 filesystem.
#
# Copyright (c) 2013 Hannes Reinecke, SuSE Labs
# All rights reserved.
#
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions are met:
#
#    Redistributions of source code must retain the above copyright notice,
#    this list of conditions and the following disclaimer.
#    Redistributions in binary form must reproduce the above copyright
#    notice, this list of conditions and the following disclaimer in the
#    documentation and/or other materials provided with the distribution.
#    Neither the name of the SuSE Labs nor the names of its contributors
#    may be used to endorse or promote products derived from this software
#    without specific prior written permission.
#
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
# AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
# IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
# ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE
# LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
# CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
# SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
# INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
# CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
# ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF
# THE POSSIBILITY OF SUCH DAMAGE.
#

rand() {
    local devsize=$1
    local r
    local rmult
    local ret=$RANDOM

    r=$devsize
    rmult=0
    while [ $r -gt 32767 ] ; do
	r=$(( r / 32767 ))
	(( rmult++ ))
    done

    while [ $rmult -gt 0 ] ; do
	ret=$(( ret * 32767 + RANDOM))
	(( rmult-- ))
    done
    ret=$(( ret % devsize ))
    echo $ret
}

dev=$1
if [ ! -b $dev ] ; then
    echo "$dev is not a block device"
    exit 1
fi

tsize=$2

devsize=$(awk "/${dev##*/}/ { printf(\"%s\n\", \$3); }" /proc/partitions)
blksize=$(dumpe2fs $dev 2>/dev/null | sed -n "s/Block size: *\([0-9]*\)/\1/p")
if [ -z "$blksize" ] || [ $blksize -eq 0 ] ; then
    echo "No valid filesystem on device $dev"
    exit 1
fi

blkmult=$(( 1024 / blksize ))

freelist=$(dumpe2fs $dev 2> /dev/null | sed -n 's/^  Free blocks: \([0-9]*-[0-9]*\)/\1/p')

blks=$(( tsize * blkmult ))
while (( $blks )) ; do
    bnum=$(rand $devsize)
    for f in $freelist ; do
	: $f
	bstart=${f%-*}
	bend=${f#*-}
	if [ $bnum -ge $bstart -a $bnum -lt $bend ] ; then
	    echo $bnum
	    (( blks-- ))
	fi
    done
done

if (( $blks )) ; then
    echo "Not enough free blocks on device $dev"
    exit 1
fi
