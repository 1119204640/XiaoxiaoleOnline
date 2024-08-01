local skynet = require "skynet"
local skynet_manager = require "skynet.manager"
local runconfig = require "runconfig"
local time = require "time"
local util = require "util"
local log = require "log"

local daemon = runconfig["daemon"]
local logpath = runconfig["logpath"]
local logfile = io.open(logpath, "a+")
local auto_relog = runconfig["auto_relog"]
local sighup_file = runconfig["sighup_file"]

local function write_log(file, str)
    file:write(str, "\n")
    file:flush()
end

local function reopen_log()
    logfile:close()
    logfile = io.open(logpath, "a+")
end

local function auto_reopen_log()

	local now = time.now()
    local futrue = time.next_day() - now
    skynet.timeout(futrue * 100, auto_reopen_log)

	local date = os.date("%Y-%m-%d", now)
    local newname = string.format("%s.%s", logpath, date)
    os.rename(logpath, newname)
    reopen_log()
end

local last_time = 0
local last_str_time
local function get_str_time()
    local now = time.now()
    if last_time ~= now then
        last_str_time = os.date("%Y-%m-%d %H:%M:%S", now)
    end
    return last_str_time
end

local sighup_cmd = {}

function sighup_cmd.stop()
    log.warn("开始关闭服务器")
	skynet.call("admin", "lua", "stop")
end

function sighup_cmd.reload()
    log.warn("开始重启")
    skynet.call(".main", "lua", "reload")
    log.warn("重启结束")
end

local function get_sighup_cmd()
    local cmd = util.get_first_line(sighup_file)
	log.info("信号cmd:" .. cmd)
    if not cmd then
        return
    end
    cmd = util.trim(cmd)
    return sighup_cmd[cmd]
end

skynet.register_protocol({
   	name = "text",
    id = skynet.PTYPE_TEXT,
    unpack = skynet.tostring,
    dispatch = function(_, addr, str)
        local time = get_str_time()
        str = string.format("[%08x][%s] %s", addr, time, str)
       	if not daemon then
           	print(str)
        end
       	write_log(logfile, str)
    end
})

-- 捕捉sighup信号(kill -1)
skynet.register_protocol({
   	name = "SYSTEM",
    id = skynet.PTYPE_SYSTEM,
   	unpack = function(...) return ... end,
   	dispatch = function()
       	local func = get_sighup_cmd()
       	if func then
           	func()
       	else
           	log.error(string.format("找不到信号类型文件：'%s'或cmd出错", sighup_file))
       	end
   	end
})

local CMD = {}

skynet.start(function()
    --skynet.register ".log"
    skynet.dispatch("lua", function(_, _, cmd, ...)
        local f = CMD[cmd]
        if f then
            skynet.ret(skynet.pack(f(...)))
        else
            log.error("Invalid cmd. cmd:", cmd)
        end
    end)

    if auto_relog then
        local ok, msg = pcall(auto_reopen_log)
        if not ok then
            if not daemon then
                print(msg)
            end
            write_log(logfile, msg)
        end
    end
end)

