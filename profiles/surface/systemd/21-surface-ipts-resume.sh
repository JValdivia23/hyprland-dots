#!/usr/bin/env bash
# Microsoft Surface post-resume hook for IPTS touchscreen re-enumeration
case "$1/$2" in
    post/*)
        # Give IPTS / MEI controller 1s to finish power-state handshake
        sleep 1
        udevadm trigger -s hidraw
        ;;
esac
