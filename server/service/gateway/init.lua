local skynet = require "skynet"
local s = require "service"
local socket = require "skynet.socket"
local runconfig = require "runconfig"
local protocol = require "protocol"
local util = require "util"

conns = {} -- [fd] = conn
players = {}  -- [playerid] = gateplayer
local closing = false

-- 协议格式: msg = {cmd, arg1, arg2, ...}
local str_unpack = function(msgstr)

	local msg = {}

	while true do
		local arg, rest = string.match(msgstr, "(.-),(.*)")
		if arg then
			table.insert(msg, arg)
			msgstr = rest
		else
			table.insert(msg, msgstr)
			break
		end
	end

	return msg[1], msg
end

local str_pack = function(cmd, msg)

	return table.concat(msg, ",") .. "\r\n"
end

s.resp.shutdown = function()
	closing = true
end

s.resp.send_by_fd = function(source, fd, msg, cmd)

	if not conns[fd] then
		return
	end

	local buff = util.msg_pack(cmd, msg)
	--local buff = str_pack(msg[1], msg)
	socket.write(fd, buff)
end

s.resp.send = function(source, playerid, msg, cmd)

	local gplayer = players[playerid]
	if gplayer == nil then
		return
	end
	local c = gplayer.conn
	if c == nil then
		return
	end

	s.resp.send_by_fd(nil, c.fd, msg, cmd)
end

s.resp.sure_agent = function(source, fd, playerid, agent)

	local conn = conns[fd]
	if not conn then
		skynet.call("agentmgr", "lua", "reqkick", playerid, "未完成登录就下线")
		return false
	end

	conn.playerid = playerid

	local gplayer = gateplayer()
	gplayer.playerid = playerid
	gplayer.agent = agent
	gplayer.conn = conn
	players[playerid] = gplayer
	skynet.error("sure_agent", gplayer, playerid, agent, conn)

	return true
end

local disconnect = function(fd)

	local c = conns[fd]
	if not c then
		return
	end

	local playerid = c.playerid

	if not playerid then
		return
	else
		players[playerid] = nil
		local reason = "断线"
		skynet.call("agentmgr", "lua", "reqkick", playerid, reason)
	end
end

-- agentmgr主动通知断开
s.resp.kick = function(source, playerid)

	local gplayer = players[playerid]
	if not gplayer then
		return
	end

	local c = gplayer.conn
	players[playerid] = nil

	if not c then
		return
	end
	conns[c.fd] = nil
	disconnect(c.fd)
	socket.close(c.fd)
end

local process_msg = function(fd, cmd, msg)

	skynet.error("recv " .. fd .. " [" .. cmd .. "] ")

	local conn = conns[fd]
	local playerid = conn.playerid

	if not playerid then
		local node = skynet.getenv("node")
		local nodecfg = runconfig[node]
		local loginid = math.random(1, #nodecfg.login)
		local login = "login" .. loginid
		skynet.send(login, "lua", "client", fd, cmd, msg)
	else
		local gplayer = players[playerid]
		local agent = gplayer.agent
		skynet.error("process_msg", agent, gplayer, playerid)
		skynet.send(agent, "lua", "client", cmd, msg)
	end
end

local process_buff = function(fd, readbuff)

	while true do

		--local msgstr, rest = string.match(readbuff, "(.-)\r\n(.*)")
		local cmd, msgstr, rest = util.msg_unpack(readbuff)
		if msgstr then
			readbuff = rest
			process_msg(fd, cmd, msgstr)
		else
			return readbuff
		end
	end
end

local recv_loop = function(fd)

	skynet.error("socket connected " .. fd)
	socket.start(fd)
	local readbuff = ""

	while true do
		
		local recvstr = socket.read(fd)
		if recvstr then
			readbuff = readbuff .. recvstr
			readbuff = process_buff(fd, readbuff)
		else
			skynet.error("socket close " .. fd)
			disconnect(fd)
			socket.close(fd)
			return
		end
	end
end

function conn()

	local m = {
		fd = nil,
		playerid = nil,
	}
	return m
end

function gateplayer()

	local m = {
		playerid = nil,
		agent = nil,
		conn = nil,
	}
	return m
end

local connent = function(fd, addr)

	if closing then
		return
	end
	skynet.error("connentc from:", fd, addr)

	local c = conn()
	conns[fd] = c
	c.fd = fd
	skynet.fork(recv_loop, fd)
end

function s.init()

	local node = skynet.getenv("node")
	local nodecfg = runconfig[node]
	local port = nodecfg.gateway[s.id].port

	local listenfd = socket.listen("0.0.0.0", port)
	skynet.error("listen socket " .. "0.0.0.0,", port)
	socket.start(listenfd, connent)
end

s.start(...)
