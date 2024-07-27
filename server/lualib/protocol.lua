Protocol = {
	ReqLogin = 1,
	ResLogin = 2,
}

Protocol.GetProtocolName = function(pid)

	for k, v in pairs(Protocol) do
		if v == pid then
			return k
		end
	end

	return nil
end

return Protocol
