local skynet = require "skynet"
local s = require "service"
local protocol = require "protocol"
local pb = require "protobuf"
pb.register_file("/root/workspace/git_project/XiaoxiaoleOnline/server/proto/client_msg.pb")

s.client = {}
s.gate = nil

require "scene"

-- source是自带的,skynet.send自带的第一个参数
s.resp.client = function(source, cmd, msg)

	s.gate = source
	local cmd_name = protocol.GetProtocolName(cmd)
	if s.client[cmd_name] then
		local ret_msg, ret_cmd = s.client[cmd_name](msg, source, cmd_name, cmd)
		if ret_msg then
			skynet.send(source, "lua", "send", s.id, ret_msg, ret_cmd)
		end
	else
		skynet.error("s.resp.client fail", cmd)
	end
end

-- 保存玩家数据
s.resp.kick = function(source)

	s.leave_scene()
	skynet.sleep(200)
end

s.resp.exit = function(source)
	skynet.exit()
end

s.resp.send = function(source, msg, cmd)

	skynet.send(s.gate, "lua", "send", s.id, msg, cmd)
end

s.init = function()

	skynet.sleep(200)
	s.data = {
	}
end

s.start(...)
