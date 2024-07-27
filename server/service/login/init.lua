local skynet = require "skynet"
local s = require "service"
local protocol = require "protocol"
local pb = require "protobuf"
local log = require "log"
pb.register_file("/root/workspace/git_project/XiaoxiaoleOnline/server/proto/client_msg.pb")

s.client = {}
s.resp.client = function(source, fd, cmd, msg)

	log.debug("s.resp.client ", source, fd, cmd, msg)
	local cmd_name = protocol.GetProtocolName(cmd)
	if s.client[cmd_name] then
		local ret_msg = s.client[cmd_name](fd, msg, source, cmd_name, cmd)
		skynet.send(source, "lua", "send_by_fd", fd, ret_msg, cmd)
	else
		log.error("s.resp.client fail", cmd)
	end
end

s.client.ReqLogin = function(fd, msg, source, cmd_name)

	local umsg = pb.decode("client_msg." .. cmd_name, msg)
	local playerid = umsg.id
	local pw = umsg.pw
	local gate = source
	node = skynet.getenv("node")

	local reply = {}
	local reply_name = "client_msg.ResLogin"

	if pw ~= 123 then
		reply.code = 1
		reply.result = "密码错误"
		local pb_reply = pb.encode(reply_name, reply)
		return pb_reply
	end

	local isok, agent = skynet.call("agentmgr", "lua", "reqlogin", playerid, node, gate)
	if not isok then
		reply.code = 1
		reply.result = "请求mgr失败"
		local pb_reply = pb.encode(reply_name, reply)
		return pb_reply
	end

	local isok = skynet.call(gate, "lua", "sure_agent", fd, playerid, agent)
	if not isok then
		reply.code = 1
		reply.result = "gate注册失败"
		local pb_reply = pb.encode(reply_name, reply)
		return pb_reply
	end
	log.debug("login succ" .. playerid)
	reply.code = 0
	reply.result = "登录成功"
	local pb_reply = pb.encode(reply_name, reply)
	return pb_reply
end

s.start(...)
