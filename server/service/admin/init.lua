local skynet = require "skynet"
local socket = require "skynet.socket"
local s = require "service"
local runconfig = require "runconfig"
local log = require "log"

require "skynet.manager"

s.init = function()

	local port = runconfig.admin.port
	local listenfd = socket.listen("127.0.0.1", port)
	socket.start(listenfd, connect)
end

function shutdown_gate()

	for node, _ in pairs(runconfig.cluster) do
		local nodecfg = runconfig[node]
		for i, v in pairs(nodecfg.gateway or {}) do
			local name = "gateway" .. i
			log.info("正在关闭网关服:", name)
			s.call(node, name, "shutdown")
		end
	end
end

function shutdown_agent()

	local anode = runconfig.agentmgr.node
	log.info("正在关闭代理管理服:", name)
	while true do
		local online_num = s.call(anode, "agentmgr", "shutdown", 3)
		if online_num <= 0 then
			break
		end
		skynet.sleep(1)
	end
end

function stop()

	shutdown_gate()
	shutdown_agent()
	skynet.abort()

	return "ok"
end

function connect(fd, addr)

	socket.start(fd)
	--socket.write(fd, "Please enter cmd\r\n")
	local cmd = socket.readline(fd, "\r\n")
	if cmd == "stop" then
		socket.write(fd, "正在关闭服务器\r\n")
		stop()
		socket.write(fd, "关闭服务器成功\r\n")
	end
end

s.start(...)
