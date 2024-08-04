#!/bin/sh

#通过信号进行关服
echo "stop" > sighup_file
kill -1 $(cat skynet.pid)
sleep 1
echo "" > sighup_file
