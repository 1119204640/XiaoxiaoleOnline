local skynet = require "skynet"
local s = require "service"
local protocol = require "protocol"
local pb = require "protobuf"
pb.register_file("/root/workspace/git_project/XiaoxiaoleOnline/server/proto/client_msg.pb")

s.client = {}
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


local balls = {}
local foods = {}
local food_maxid = 0
local food_count = 0

function ball()

	local m = {
		playerid = nil,
		node = nil,
		agent = nil,
		x = math.random(0, 100),
		y = math.random(0, 100),
		size = 2,
		speedx = 0,
		speedy = 0,
		speed = 5,
	}

	return m
end

function food()

	local m = {
		id = nil,
		x = math.random(0, 100),
		y = math.random(0, 100),
	}

	return m
end

local function balllist_msg()

	local msg = { balls = {} }
	for i, v in pairs(balls) do
		local ball = {}
		ball.id = v.playerid
		ball.x = v.x
		ball.y = v.y
		ball.y = v.size
		table.insert(msg.balls, ball)
	end

	local pb_msg = pb.encode("client_msg.InfBallList", msg)
	return pb_msg
end

local function foodlist_msg()

	local msg = { foods = {} }
	for i, v in pairs(foods) do
		local food = {}
		food.id = v.id
		food.x = v.x
		food.y = v.y
		foode.size = v.size
		table.insert(msg.foods, food)
	end

	local pb_msg = pb.encode("client_msg.InfFoodList", msg)
	return pb_msg
end

function broadcast(msg, cmd)

	for i, v in pairs(balls) do
		s.send(v.node, v.agent, "send", msg, cmd)
	end
end

s.resp.enter = function(source, playerid, node, agent)

	if balls[playerid] then
		return false
	end
	local b = ball()
	b.playerid = playerid
	b.node = node
	b.agent = agent

	local entermsg = {b = {id = playerid, x = b.x, y = b.y, size = b.size}}
	local pb_msg = pb.encode("client_msg.InfEnter", entermsg)
	broadcast(pb_msg, cmd, 10)

	balls[playerid] = b
	local ret_msg = {code = 0, result = "进入成功"}
	pb_msg = pb.encode("client_msg.ResEnter", ret_msg)
	s.send(b.node, b.agent, "send", pb_msg, 4)

	s.send(b.node, b.agent, "send", balllist_msg(), 11)
	s.send(b.node, b.agent, "send", foodlist_msg(), 12)
	return true
end

s.resp.leave = function(source, playerid)

	if not balls[playerid] then
		return false
	end

	balls[playerid] = nil

	local leavemsg = {id = playerid}
	local pb_msg = pb.encode("client_msg.InfLeaveScene", leavemsg)
	broadcast(pb_msg, 9)
end

s.client.ReqShift = function(msg, source, cmd_name, cmd)

	local b = balls[playerid]
	if not b then
		return false
	end
	local umsg = pb.decode("client_msg." .. cmd_name, msg)
	local x = umsg.x
	local y = umsg.y
	b.speedx = x
	b.speedy = y

	local ball_msg = {b = {id = playerid, x = b.x, y = b.y, size = b.size, speed = b.speed, speedx = b.speedx, speedy = b.speedy}}
	local pb_msg = pb.encode("client_msg.ResShift", msg)
	broadcast(pb_msg, cmd, 8)
end

function update(frame)
	food_update()
	move_update()
	eat_update()
end

s.init = function()
	skynet.fork(function()
		local stime = skynet.now()
		local frame = 0
		while true do
			frame = frame + 1
			local isok, err = pcall(update, frame)
			if not isok then
				skynet.error(err)
			end
			local etime = skynet.now()
			local waittime = frame * 10 - (etime - stime)
			if waittime <= 0 then
				waittime = 2
			end
			skynet.sleep(waittime)
		end
	end)
end

function move_update()
	local cmd = 13

	for i, v in pairs(balls) do
		v.x = v.x + v.speedx * v.speed
		v.y = v.y + v.speedy * v.speed
		if v.speedx ~= 0 or v.speedy ~= 0 then
			local msg = {id = v.playerid, vx = v.x, vy = v.y}
			pb_msg = pb.encode("client_msg.InfMove", msg)
			broadcast(pb_msg, cmd)
		end
	end
end

function food_update()
	if food_count > 50 then
		return
	end

	if math.random(1, 100) < 98 then
		return
	end

	food_maxid = food_maxid + 1
	food_count = food_count + 1
	local f = food()
	f.id = food_maxid
	foods[f.id] = f

	local cmd = 14
	local msg = { 
		foods = {
			{id = f.id, x = f.x, y = f.y},
		}
	}
	pb_msg = pb.encode("client_msg.InfAddFood", msg)
	broadcast(pb_msg, cmd)
end

function eat_update()

	local cmd = 15

	for pid, b in pairs(balls) do
		for fid, f in pairs(foods) do
			if (b.x - f.x) ^ 2 + (b.y - f.y) ^ 2 < b.size ^ 2 then
				b.size = b.size + 1
				food_count = food_count - 1
				local msg = {id = b.playerid, fid = fid, size = b.size}
				pb_msg = pb.encode("client_msg.InfEatFood", msg)
				broadcast(pb_msg, cmd)
				foods[fid] = nil
			end
		end
	end
end

s.start(...)
