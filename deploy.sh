#!/bin/bash
set -x verbose #echo on

coffee --bare -c */**.coffee
rsync --delete-excluded \
  --exclude '.git*' \
  --exclude 'deploy.sh' \
  --exclude '*.coffee' \
  -va $(pwd) ~/Public

open ~/Dropbox/Public/$(basename `pwd`)
