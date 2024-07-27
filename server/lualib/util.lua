util = {}

-- 协议格式,2字节的长度+4字节的协议ID+协议体(protobuf)
util.msg_unpack = function(readbuff)

	local msgstr = nil
	local buff_len = string.len(readbuff)

	if buff_len < 4 then
		return nil, msgstr,readbuff
	end

	local message_len, cmd = string.unpack("> i2 i4", readbuff)
	-- 粘包
	if message_len > buff_len then
		return cmd, msgstr,readbuff
	end

	local format = string.format("> c%d", message_len - 6)
	msgstr = string.unpack(format, readbuff, 7)

	readbuff = string.sub(readbuff, message_len + 1)
	return cmd, msgstr, readbuff
end

-- 协议格式,2字节的长度+4字节的协议ID+协议体(protobuf)
util.msg_pack = function(cmd, msg)

	local msg_len = string.len(msg)
	local len = msg_len + 2 + 4
	local str_format = string.format("> i2 i4 c%d", msg_len)
	local buff = string.pack(str_format, len, cmd, msg)

	return buff
end

return util
