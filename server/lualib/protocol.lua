Protocol = {
	ReqLogin = 1,
	ResLogin = 2,
	ReqEnter = 3,
	ResEnter = 4,
	ReqLeaveScene = 5,
	ResLeaveScene = 6,
	ReqShift = 7,
	ResShift = 8,
	InfLeaveScene = 9,
	InfEnter = 10,
	InfBallList = 11,
	InfFoodList = 12,
	InfMove = 13,
	InfAddFood = 14,
	InfEatFood = 15,
	ReqRegister = 16,
	ResRegister = 17,
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
