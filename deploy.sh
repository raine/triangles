#!/bin/bash
set -x verbose #echo on

coffee -c triangles.coffee
# cp -R ../triangles ~/Dropbox/Public
rsync --delete-excluded \
  --exclude '.git*' \
  --exclude 'deploy.sh' \
  --exclude '*.coffee' \
  -vva ../triangles /Users/raine/Dropbox/Public
open ~/Dropbox/Public/triangles
