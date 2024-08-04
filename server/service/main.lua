local skynet = require "skynet"
local skynet_manager = require "skynet.manager"
local runconfig = require "runconfig"
local cluster = require "skynet.cluster"
local pb = require "protobuf"

skynet.start(function()
	skynet.error("[start main]")
	local mynode = skynet.getenv("node")
	local nodecfg = runconfig[mynode]

	local nodemgr = skynet.newservice("nodemgr", "nodemgr", 0)
	skynet.name("nodemgr", nodemgr)
	
	cluster.reload(runconfig.cluster)
	cluster.open(mynode)

	for i, v in pairs(nodecfg.gateway or {}) do
		-- 第二第三参数传递到我们封装的相应服务的name,id属性
		local srv = skynet.newservice("gateway", "gateway", i)
		-- 别名
		skynet.name("gateway" .. i, srv)
	end

	for i, v in pairs(nodecfg.login or {}) do
		local srv = skynet.newservice("login", "login", i)
		skynet.name("login" .. i, srv)
	end

	local anode = runconfig.agentmgr.node
	if mynode == anode then
		local srv = skynet.newservice("agentmgr", "agentmgr", 0)
		skynet.name("agentmgr", srv)
	else
		local proxy = cluster.proxy(anode, "agentmgr")
		skynet.name("agentmgr", proxy)
	end

	if mynode == anode then
		local srv = skynet.newservice("admin", "admin", 0)
		skynet.name("admin", srv)
	else
		local proxy = cluster.proxy(anode, "admin")
		skynet.name("admin", proxy)
	end

	local daemon = runconfig.daemon
	if daemon then
		local srv = skynet.newservice("log", "log", 0)
		skynet.name("log", srv)
	end

	for _, sid in pairs(runconfig.scene[mynode] or {}) do
		local srv = skynet.newservice("scene", "scene", sid)
		skynet.name("scene" .. sid, srv)
	end

	skynet.exit()
end)
