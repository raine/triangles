#!/bin/bash
set -x verbose #echo on

coffee --bare -c */**.coffee
rsync --delete-excluded \
  --exclude '.git*' \
  --exclude 'deploy.sh' \
  --exclude '*.coffee' \
  -va ../triangles /Users/raine/Dropbox/Public
open ~/Dropbox/Public/triangles
