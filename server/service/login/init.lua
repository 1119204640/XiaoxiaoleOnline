local skynet = require "skynet"
local s = require "service"
local protocol = require "protocol"
local pb = require "protobuf"
pb.register_file("/root/workspace/git_project/XiaoxiaoleOnline/server/proto/client_msg.pb")
local log = require "log"
local mysql = require "skynet.db.mysql"
local db = nil
local md5 = require "md5"

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

s.client.ReqRegister = function(fd, msg, source, cmd_name)

	local umsg = pb.decode("client_msg." .. cmd_name, msg)
	local name = umsg.name
	local pw = umsg.pwd
	local md5_pw = md5.tohex(pw)

	local reply = {}
	local reply_name = "client_msg.ResRegister"

	local sql = string.format("insert into player (pwd, name) values (\'%s\', \'%s\')", md5_pw, name)
	local res = db:query(sql)
	sql = "select last_insert_id()"
	res = db:query(sql)

	if not res or not res[1] then
		reply.code = 1
		reply.result = "注册失败"
		local pb_reply = pb.encode(reply_name, reply)
		return pb_reply
	end

	local playerid = res[1]["last_insert_id()"] or 0
	if playerid == 0 then
		reply.code = 1
		reply.result = "注册失败"
		local pb_reply = pb.encode(reply_name, reply)
		return pb_reply
	end
	reply.code = 0
	reply.playerid = playerid
	local pb_reply = pb.encode(reply_name, reply)
	log.debug("register succ", playerid)

	return pb_reply
end

s.client.ReqLogin = function(fd, msg, source, cmd_name)

	local umsg = pb.decode("client_msg." .. cmd_name, msg)
	local playerid = umsg.id
	local pw = umsg.pwd
	local gate = source
	node = skynet.getenv("node")

	local reply = {}
	local reply_name = "client_msg.ResLogin"

	local sql = string.format("select pwd from player where playerid = \'%d\'", playerid)
	local res = db:query(sql)
	if not res or not res[1] then
		log.debug("账号不存在", playerid, pw, res, res and res[1], sql)
		reply.code = 1
		reply.result = "账号不存在"
		local pb_reply = pb.encode(reply_name, reply)
		return pb_reply
	end

	local md5_pw = md5.tohex(pw)
	local true_pwd = res[1].pwd
	if md5_pw ~= true_pwd then
		log.debug("密码错误", playerid, pw, true_pwd, md5_pw)
		reply.code = 1
		reply.result = "密码错误"
		local pb_reply = pb.encode(reply_name, reply)
		return pb_reply
	end

	local isok, agent = skynet.call("agentmgr", "lua", "reqlogin", playerid, node, gate)
	if not isok then
		log.debug("请求mgr失败", playerid)
		reply.code = 1
		reply.result = "请求mgr失败"
		local pb_reply = pb.encode(reply_name, reply)
		return pb_reply
	end

	local isok = skynet.call(gate, "lua", "sure_agent", fd, playerid, agent)
	if not isok then
		log.debug("gate注册失败", playerid)
		reply.code = 1
		reply.result = "gate注册失败"
		local pb_reply = pb.encode(reply_name, reply)
		return pb_reply
	end
	log.debug("login succ", playerid)
	reply.code = 0
	reply.result = "登录成功"
	local pb_reply = pb.encode(reply_name, reply)
	return pb_reply
end

function s.init()

	db = mysql.connect({
		host = "127.0.0.1",
		port = 3306,
		database = "dpzj",
		user = "root",
		password = "12345678aB-",
		max_packet_size = 1024 * 1024,
		on_connect = nil
	})
end

s.start(...)
