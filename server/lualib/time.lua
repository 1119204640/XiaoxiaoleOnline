local skynet = require "skynet"

local M = {}

M.now = function()

	return math.floor(skynet.time())
end

M.date = function(time)

	return os.date("%Y-%m-%d %H:%M:%S", time)
end

M.today = function(now)

	now = now or M.now()

    local t = os.date("*t", now)
    local today = {
        year = t.year,
        month = t.month,
        day = t.day,
        hour = 0,
        min = 0,
        sec = 0,
    }

    return os.time(today)
end

M.next_day = function(now)

	local today = M.today(now)

	return today + 24 * 86400
end

return M	
