local skynet = require "skynet"
local s = require "service"
local runconfig = require "runconfig"
local mynode = skynet.getenv("node")
local protocol = require "protocol"
local pb = require "protobuf"
pb.register_file("/root/workspace/git_project/XiaoxiaoleOnline/server/proto/client_msg.pb")

s.snode = nil
s.sname = nil

local function random_scene()

	local nodes = {}
	for i, v in pairs(runconfig.scene) do
		table.insert(nodes, i)
		if runconfig.scene[nodes] then
			table.insert(nodes, mynode)
		end
	end
	local idx = math.random(1, #nodes)
	local scenenode = nodes[idx]
	local scenelist = runconfig.scene[scenenode]
	local idx = math.random(1, #scenelist)
	local sceneid = scenelist[idx]
	return scenenode, sceneid
end

s.client.ReqEnter = function(msg)
	local reply = {}
	local reply_name = "client_msg.ResEnter"
	if s.sname then
		reply.code = 1
		reply.result = "已在场景"
		local pb_reply = pb.encode(reply_name, reply)
		return pb_reply, 4
	end
	local snode, sid = random_scene()
	local sname = "scene" .. sid
	local isok = s.call(snode, sname, "enter", s.id, mynode, skynet.self())
	if not isok then
		reply.code = 1
		reply.result = "进入失败"
		local pb_reply = pb.encode(reply_name, reply)
		return pb_reply, 4
	end
	s.snode = snode
	s.sname = sname
	reply.code = 0
	reply.result = "进入成功"
	local pb_reply = pb.encode(reply_name, reply)
	return pb_reply, 4
end

s.client.ReqLeavaScene = function()

	if not s.sname then
		return
	end
	s.call(s.snode, s.sname, "leave", s.id)
	s.snode = nil
	s.sname = nil
	local reply = {}
	local reply_name = "client_msg.ResLeaveScene"
	local pb_reply = pb.encode(reply_name, reply)
	return pb_reply, 6
end

s.client.ReqShift = function(msg, source, cmd_name, cmd)

	if not s.sname then
		return
	end

	s.call(s.snode, s.sname, "client", cmd, msg)
end
