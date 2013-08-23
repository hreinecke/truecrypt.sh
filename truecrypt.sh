#!/bin/bash
#
# truecrypt.sh
# deniable filesystem in bash
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

gen_table() {
    local dev=$1
    local bmult=$2
    local blklist
    local bstart=0
    local b bnum blk boffset bsize

    blklist=$(dumpe2fs -b $dev 2>/dev/null)
    for b in $blklist ; do
	: $b
	bnum=$(( b * bmult ))
	if [ -z "$blk" ] ; then
	    blk=$(( b + 1 ))
	elif [ $blk -ne $b ] ; then  
	    echo "$bstart $bsize linear $dev $boffset"
	    bstart=$(( bstart + $bsize ))
	    blk=$(( b + 1 ))
	    bsize=0
	    unset boffset
	else
	    (( blk++ ))
	fi
	if [ -z "$boffset" ] ; then
	    boffset=$bnum
	fi
	(( bsize += bmult ))
    done
    echo "$bstart $bsize linear $dev $boffset"
}

gen_inv_table() {
    local dev=$1
    local bmult=$2
    local blklist
    local blk=0
    local bend=0
    local blksize=1
    local b bsize bstart bend

    blklist=$(dumpe2fs -b $dev 2>/dev/null)
    for b in $blklist ; do
	: $b
	if [ $blk -ne $b ] ; then
	    if [ -n "$bstart" ] ; then
		bsize=$(( blk * bmult - bstart ))
		echo "$bstart $bsize error"
	    fi
	    bstart=$(( blk * bmult ))
	    bend=$(( b * bmult ))
	    bsize=$(( bend - bstart ))
	    : $bstart $bend $bsize
	    echo "$bstart $bsize linear $dev $bstart"
	    bstart=$(( bstart + bsize ))
	fi
	blk=$(( b + 1 ))
    done
    bsize=$(( blk * bmult - bstart ))
    echo "$bstart $bsize error"
    bend=$(awk "/${dev##*/}/ { printf(\"%s\n\", \$3); }" /proc/partitions)
    bstart=$(( blk  * bmult ))
    bend=$(( bend * bmult ))
    bsize=$(( bend - bstart ))
    echo "$bstart $bsize linear $dev $bstart"
}

dev=$1
if [ ! -b $dev ] ; then
    echo "$dev is not a block device"
    exit 1
fi

blksize=$(dumpe2fs $dev 2>/dev/null | sed -n "s/Block size: *\([0-9]*\)/\1/p")
if [ -z "$blksize" ] || [ $blksize -eq 0 ] ; then
    echo "No valid filesystem on device $dev"
    exit 1
fi

blkmult=$(( blksize / 512 ))

gen_table $dev $blkmult | dmsetup create tcrypt
gen_inv_table $dev $blkmult | dmsetup create tcrypt_orig
