#!/bin/sh

##########################################################################
#
#    arm-toolchain
#    Copyright (C) 2011  Alexander Karpich
#
#    This program is free software: you can redistribute it and/or modify
#    it under the terms of the GNU General Public License as published by
#    the Free Software Foundation, either version 3 of the License, or
#    (at your option) any later version.
#
#    This program is distributed in the hope that it will be useful,
#    but WITHOUT ANY WARRANTY; without even the implied warranty of
#    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#    GNU General Public License for more details.
#
#    You should have received a copy of the GNU General Public License
#    along with this program.  If not, see <http://www.gnu.org/licenses/>.
#
##########################################################################

gcc-ver=/usr/bin/gcc-4.4
if [ ! -e $gcc-ver ]; then
        echo "Error:  $gcc-ver not found, check gcc-ver in script ";
	exit 1;
fi
export CC=$gcc-ver

ROOT=`pwd`
source-directory=$ROOT/src
build-directory=$ROOT/build
PREFIX=$ROOT/gnuarm

#----------------------------------------------------------------------
#-----Please, check the follow links and versions of software----------

gcc-url=http://ftp.gnu.org/pub/gnu/gcc/gcc-4.4.2/gcc-4.4.2.tar.bz2
newlib-url=ftp://sources.redhat.com/pub/newlib/newlib-1.18.0.tar.gz
gdb-url=ftp://sourceware.org/pub/insight/releases/insight-6.8-1.tar.bz2
binutils-url=http://ftp.gnu.org/gnu/binutils/binutils-2.20.tar.bz2

gcc-ver=4.4.2
newlib_version=1.18.0
gdb-version=6.8-1
binutils-version=2.20

gcc-directory=gcc-$gcc-ver
newlib-directory=newlib-$newlib_version
gdb-directory=insight-$gdb-version
binutils-directory=binutils-$binutils-version

#----------------------------------------------------------------------
#----This function needs to unpackage source code from archive---------

unpack_source()
{
(
    cd $source-directory
	#---Check archive suffix---
    ARCHIVE_SUFFIX=${1##*.}
    if [ "$ARCHIVE_SUFFIX" = "gz" ]; then
      tar zxvf $1
    elif [ "$ARCHIVE_SUFFIX" = "bz2" ]; then
      tar jxvf $1
    else
      echo "Unknown archive format for $1"
      exit 1
    fi
)
}

mkdir -p $source-directory $build-directory $PREFIX

(
cd $source-directory

unpack_source $(basename $gcc-url)
unpack_source $(basename $binutils-url)
unpack_source $(basename $newlib-url)
unpack_source $(basename $gdb-url)
)

OLD_PATH=$PATH
export PATH=$PREFIX/bin:$PATH

#----------------------------------------------------------------------
#----------------------------binutils----------------------------------

(
mkdir -p $build-directory/$binutils-directory
cd $build-directory/$binutils-directory

$source-directory/$binutils-directory/configure --target=arm-elf --prefix=$PREFIX \
    --disable-werror --enable-interwork --enable-multilib \
    && make all install
) || exit 1

(
MULTILIB_CONFIG=$source-directory/$gcc-directory/gcc/config/arm/t-arm-elf

echo "

MULTILIB_OPTIONS    += mhard-float/msoft-float
MULTILIB_DIRNAMES   += fpu soft
MULTILIB_EXCEPTIONS += *mthumb/*mhard-float*


MULTILIB_OPTIONS += mno-thumb-interwork/mthumb-interwork
MULTILIB_DIRNAMES += normal interwork



" >> $MULTILIB_CONFIG


#----------------------------------------------------------------------
#-------Now we can make and install all software-----------------------
#----------------------------------------------------------------------

#----------------------------------------------------------------------
#---------------------------GCC compiler-------------------------------

mkdir -p $build-directory/$gcc-directory
cd $build-directory/$gcc-directory

$source-directory/$gcc-directory/configure --target=arm-elf --prefix=$PREFIX \
    --enable-interwork --enable-multilib \
    --disable-__cxa_atexit \
    --enable-languages="c,c++" --with-newlib \
    --with-headers=$source-directory/$newlib-directory/newlib/libc/include \
    && make all-gcc install-gcc
) || exit 1

#----------------------------------------------------------------------
#----------------------------newlib------------------------------------

(

mkdir -p $build-directory/$newlib-directory
cd $build-directory/$newlib-directory

$source-directory/$newlib-directory/configure --target=arm-elf --prefix=$PREFIX \
    --enable-interwork --enable-multilib \
    && make all install
) || exit 1


(
cd $build-directory/$gcc-directory

make all install
) || exit 1


(
mkdir -p $build-directory/$gdb-directory
cd $build-directory/$gdb-directory

$source-directory/$gdb-directory/configure --target=arm-elf --prefix=$PREFIX \
    --disable-werror --enable-interwork --enable-multilib \
    && make all install
) || exit 1

echo "All operation complete!"
