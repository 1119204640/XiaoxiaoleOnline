local skynet = require "skynet"
local s = require "service"

STATUS = {
	LOGIN = 2,
	GAME = 3,
	LOGOUT = 4,
}

local players = {}

function mgrplayer()

	local m = {
		playerid = nil,
		node = nil,
		agent = nil,
		status = nil,
		--网关地址
		gate = nil,
	}
	return m
end

s.resp.reqlogin = function(source, playerid, node, gate)
	
	local mplayer = players[playerid]
	skynet.error("xxxxx1", source, node, gate, playerid, mplayer)
	if mplayer and mplayer.status == STATUS.LOGOUT then
		skynet.error("reqlogin fail, at status LOGOUT " .. playerid)
		return false
	end

	if mplayer and mplayer.status == STATUS.LOGIN then
		skynet.error("reqlogin fail, at status LOGIN " .. playerid)
		return false
	end

	if mplayer then
		local pnode = mplayer.node
		local pagent = mplayer.agent
		local pgate = mplayer.gate
		mplayer.status = STATUS.LOGOUT
		s.call(pnode, pagent, "kick")
		s.send(pnode, pgate, "exit")
		s.send(pnode, pgate, "send", playerid, {"kick", "顶替下线"})
		s.call(pnode, pgate, "kick", playerid)
	end

	local player = mgrplayer()
	player.playerid = playerid
	player.node = node
	player.gate = gate
	player.agent = nil
	player.STATUS = STATUS.LOGIN
	players[playerid] = player
	local agent = s.call(node, "nodemgr", "newservice", "agent", "agent", playerid)
	skynet.error("lllll2", node, playerid, agent)
	player.agent = agent
	player.status = STATUS.GAME
	return true, agent
end

s.resp.reqkick = function(source, playerid, reason)

	local mplayer = players[playerid]
	if not mplayer then
		return false
	end

	if mplayer.status ~= STATUS.GAME then
		return false
	end

	local pnode = mplayer.node
	local pagent = mplayer.agent
	local pgate = mplayer.gate
	mplayer.status = STATUS.LOGOUT

	s.call(pnode, pagent, "kick")
	s.send(pnode, pagent, "exit")
	s.send(pnode, pgate, "kick", playerid)
	players[playerid] = nil

	return true
end

s.start(...)
