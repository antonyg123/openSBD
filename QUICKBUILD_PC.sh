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
# prerequisites are installed. Tested on Ubuntu 16.04 64-bit and Buildroot Zedboard.

#######################################################################
#                      Building openSBD for PC                        #
#######################################################################

# -e: fail on error
# -E: trap on error inheritance
# -u: fail on unset variable
set -eEu
error_line() {
    echo "Error on QUICKBUILD line $1"
}

trap 'error_line $LINENO' ERR

SBD_HOME=$PWD

# Download open source cFE and OpenSplice (these are the latest available releases currently)
git clone -b 'v6.5.0a' https://github.com/nasa/cfe.git
git clone -b 'OSPL_V6_9_190403OSS_RELEASE' --depth 1 https://github.com/ADLINK-IST/opensplice.git

# Build OpenSplice
cd $PWD/opensplice

export SPLICE_HOST=x86.linux-release
export SPLICE_TARGET_ENV=x86.linux-release

# configure triggers a false positive for -e
set +e
source ./configure # Don't export SPLICE_TARGET_ENV above to get a list of target options
set -e
make

# Speed up make install by disabling docs compilation
export OSPL_DOCS=none

make install

#git apply ../patches/opensplice.patch

cd ../code

# Set up environment variables for PC compilation
export OSPL_HOME="$SBD_HOME/opensplice/install/HDE/x86.linux"
source $OSPL_HOME/release.com

make clean
make

cp *.{c,cpp,h} $SBD_HOME/cfe/cfe/fsw/cfe-core/src/sb
cp $SBD_HOME/code/libSBCommon.so $OSPL_HOME/lib
cp $SBD_HOME/code/rtps.ini $SBD_HOME/cfe/build/cpu1/exe

cd ../cfe

git submodule update --init osal

@echo "If this patch fails to apply, add the changes manually"
git apply ../patches/sbd.patch

source setvars.sh
cd build/cpu1
make realclean
cp $SBD_HOME/code/rtps.ini $SBD_HOME/cfe/build/cpu1/exe
make config
make
cd exe
./core-linux.bin

# To set environment variables run in a new shell:
#export OSPL_HOME="$PWD/opensplice/install/HDE/x86.linux"
#source $OSPL_HOME/release.com
#cd build/cpu1/exe
#./core-linux.bin

