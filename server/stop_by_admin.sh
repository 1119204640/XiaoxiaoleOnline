#!/bin/sh

#通过admin服务进行关服
cmd="stop"
ip="127.0.0.1"
port="8888"

{
	sleep 1
	echo "$cmd"
	sleep 1
}|telnet $ip $port
