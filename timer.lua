time = {}
timer = {}

function timer.newTime()
	table.insert(time, 0)
	return #time
end

function timer.update(dt)
	for i,v in pairs(time) do
		table.remove(time, i)
		table.insert(time, i, v + dt)
	end
end

-- returns time in s
function timer.get(i)
	return time[i] or 0
end

function timer.delete(i)
	table.remove(time,i)
	return 0
end

function timer.stealth()
	local mainUpdate = love.update

	love.update = function (dt)
		timer.update(dt)
		if mainUpdate then mainUpdate(dt) end
	end
end