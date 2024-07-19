local skynet = require "skynet"
local s = require "service"
local runconfig = require "runconfig"
local mynode = skynet.getenv("node")

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

s.client.enter = function(msg)
	if s.sname then
		return {"enter", 1, "已在场景"}
	end
	local snode, sid = random_scene()
	local sname = "scene" .. sid
	local isok = s.call(snode, sname, "enter", s.id, mynode, skynet.self())
	if not isok then
		return {"enter", 1, "进入失败"}
	end
	s.snode = snode
	s.sname = sname
	return nil
end

s.leave_scene = function()

	if not s.sname then
		return
	end
	s.call(s.snode, s.sname, "leave", s.id)
	s.snode = nil
	s.sname = nil
end

s.client.shift = function(msg)

	if not s.sname then
		return
	end

	local x = msg[2] or 0
	local y = msg[3] or 0
	s.call(s.snode, s.sname, "shift", s.id, x, y)
end
