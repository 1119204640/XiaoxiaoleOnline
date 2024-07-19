local skynet = require "skynet"
local cluster = require "skynet.cluster"

local M = {
	-- 类型和id
	name = "",
	id = 0,
	-- 回调函数
	exit = nil,
	init = nil,
	-- 分发方法
	resp = {},
}

function traceback(err)

	skynet.error(tostring(err))
	skynet.error(debug.traceback())
end

-- address 消息发送方
local dispatch = function(session, address, cmd, ...)

	skynet.error("dispatch", session, address, cmd)
	local fun = M.resp[cmd]
	if not fun then
		skynet.ret()
		return
	end

	-- xpcall 安全调用方法 traceback:报错时错误信息 第三个参数及后面为fun参数
	local ret = table.pack(xpcall(fun, traceback, address, ...))
	local isok = ret[1]

	if not isok then
		skynet.ret()
		return
	end

	-- 从ret中解出返回值，返回给发送方, ret从ret[2]开始才是函数返回值
	skynet.retpack(table.unpack(ret, 2))
end

function init()

	skynet.dispatch("lua", dispatch)
	if M.init then
		M.init()
	end
end

function M.call(node, srv, ...)

	local mynode = skynet.getenv("node")
	if node == mynode then
		return skynet.call(srv, "lua", ...)
	else
		return cluster.call(node, srv, ...)
	end
end

function M.send(node, srv, ...)

	local mynode = skynet.getenv("node")
	if node == mynode then
		return skynet.send(srv, "lua", ...)
	else
		return cluster.send(node, srv, ...)
	end
end

function M.start(name, id, ...)

	M.name = name
	M.id = tonumber(id)

	skynet.start(init)
end

return M
