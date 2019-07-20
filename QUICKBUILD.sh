#! /usr/bin/env bash

# Copyright (c) 2018 NSF Center for Space, High-performance, and Resilient Computing (SHREC)
# University of Pittsburgh. All rights reserved.

# Redistribution and use in source and binary forms, with or without modification, are permitted provided
# that the following conditions are met:
# 1. Redistributions of source code must retain the above copyright notice,
#    this list of conditions and the following disclaimer.
# 2. Redistributions in binary form must reproduce the above copyright notice,
#    this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
#
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, 
# INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. 
# IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR 
# CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS;
# OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT 
# (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY
# OF SUCH DAMAGE.

# This script should be all that is needed to go from a new clone of openSBD to
# a running barebones cFE with integrated OpenSplice SBD, assuming all component
# prerequisites are installed. Tested on Ubuntu 16.04 64-bit.
#
# Note 1:
# It is recommended that the beginning section (OpenSplice compile) is done
# manually in case of build errors.
#
# Note 2:
# Enter target 21 (for x86.linux-release) when prompted during OpenSplice configure
#
# Note 3:
# See comments for steps needed to compile for ARM

SBD_HOME=$PWD

# Download open source cFE and OpenSplice (these are the latest available releases currently)
git clone -b 'v6.5.0a' https://github.com/nasa/cfe.git
git clone -b 'OSPL_V6_9_190403OSS_RELEASE' --depth 1 https://github.com/ADLINK-IST/opensplice.git

# Build OpenSplice
cd $PWD/opensplice

# Disable CMSOAP compilation, done by default for newer versions of Opensplice
#export INCLUDE_SERVICES_CMSOAP=no

# To enable cross compilation
#export SPLICE_HOST=x86.linux-release
#export CROSS_COMPILE=<cross-compiler path>/arm-buildroot-linux-gnueabi-

source ./configure # Enter target 21 (x86.linux-release) or target 5 (armv7l.linux-release)
make

# Speed up make install by disabling docs compilation
export OSPL_DOCS=none

make install

patch -Np1 -i ../patches/opensplice.patch

cd ../code

# Set up environment variables for PC compilation
export OSPL_HOME="$SBD_HOME/opensplice/install/HDE/x86.linux"
source $OSPL_HOME/release.com

# Add the cross compiler to the Makefile in code and remove the -m32 flag for ARM compile
#export OSPL_HOME="$SBD_HOME/opensplice/install/HDE/armv7l.linux"
#export LD_LIBRARY_PATH="$SBD_HOME/opensplice/install/HDE/armv7l.linux/host/lib"

make

cp *.{c,cpp,h} $SBD_HOME/cfe/cfe/fsw/cfe-core/src/sb
cp $SBD_HOME/code/libSBCommon.so $OSPL_HOME/lib
cp $SBD_HOME/code/rtps.ini $SBD_HOME/cfe/build/cpu1/exe

cd ../cfe

git submodule update --init osal

patch -Np1 -i ../patches/sbd.patch

source setvars.sh
cd build/cpu1
make realclean
make config
make
cd exe
cp $SBD_HOME/code/rtps.ini $SBD_HOME/cfe/build/cpu1/exe
./core-linux.bin

