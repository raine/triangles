#!/bin/bash
set -x verbose #echo on

coffee -c triangles.coffee
# cp -R ../triangles ~/Dropbox/Public
rsync --exclude '.git' -vva ../triangles /Users/raine/Dropbox/Public
open ~/Dropbox/Public/triangles
