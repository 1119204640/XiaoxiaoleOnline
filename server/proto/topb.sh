#!/bin/sh

#sh topb.sh client_msg.proto
pro=$1;
suffix=${pro#*.}
name=${pro%.*}
tr_suff=proto
pbname=$name.pb

if [ "${suffix}" != "${tr_suff}" ]; then
	echo '请输入正确的名字'
else
	protoc --descriptor_set_out $pbname $pro
fi
