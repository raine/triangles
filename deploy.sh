#!/bin/bash
set -x verbose #echo on

coffee -c triangles.coffee
# cp -R ../triangles ~/Dropbox/Public
rsync --exclude '.git' -vva ../triangles /Users/raine/Dropbox/Public
rm -rf ~/Dropbox/Public/triangles/.git
open ~/Dropbox/Public/triangles
