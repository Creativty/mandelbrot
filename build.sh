#!/bin/sh

set -xe

make -p ./build
odin build src -out:build/viewer
