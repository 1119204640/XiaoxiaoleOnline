#!/bin/sh

echo "reload" > sighup_file
kill -1 $(cat skynet.pid)
sleep 1
echo "" > sighup_file
