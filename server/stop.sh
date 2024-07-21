#!/bin/sh

cmd="stop"
ip="127.0.0.1"
port="8888"

{
	sleep 1
	echo "$cmd"
	sleep 1
}|telnet $ip $port
