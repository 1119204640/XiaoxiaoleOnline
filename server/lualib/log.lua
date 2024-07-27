local skynet = require "skynet"
local time = require "time"
local M = {}
local types = {
	debug = 1,
	warn = 2,
	info = 3,
	error = 4,
}

function get_src_line(sta)

	local info = debug.getinfo(sta, "S")
	local path = info.short_src
	info = debug.getinfo(sta, "l")
	local line = info.currentline

	return path, line 
end

function get_log_format(str_type)

	local path, line = get_src_line(4)
	local now = os.time()
	local date = time.date(now)
	local log_format = string.format("[%s] %s %s:%d", str_type, date, path, line)

	return log_format
end

function M.debug(...)
	local log_format = get_log_format("DEBUG")
	print(log_format, ...)
	--skynet.error(log_format, ...)
end

function M.warn(...)
	local log_format = get_log_format("WARN")
	skynet.error(log_format, ...)
end

function M.info(...)
	local log_format = get_log_format("INFO")
	skynet.error(log_format, ...)
end

function M.error(...)
	local log_format = get_log_format("ERROR")
	skynet.error(log_format, ...)
	skynet.error("[ERROR]", debug.traceback())
end

return M
