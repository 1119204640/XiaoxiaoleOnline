local M = {}

M.date = function(time)

	return os.date("%Y-%m-%d %H:%M:%S", time)
end

return M	
