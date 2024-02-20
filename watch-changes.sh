#!/usr/bin/env bash

mkdir -p /tmp/ddns_updates
while inotifywait -r -e close_write /tmp/ddns_updates; do /update.sh; done

