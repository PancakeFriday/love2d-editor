editor = {}
editor.buffer = ''

editor.marginX = 40
editor.marginY = 20

editor.lineWidth = 150
editor.lineHeight = 51

editor.fontheight = 14
editor.fontwidth = 8

editor.markerX = 0
editor.markerY = 0

editor.tabsize = 4
editor.pos = 0

editor.x = 0
editor.y = 0

editor.keyTimer1 = 0
editor.keyTimer2 = 0
editor.pressedKey = ''

editor.repeatkeys = { 'backspace', 'up', 'down', 'left', 'right', 'delete', 'return'}

editor.filename = ''
editor.saveState = false

local font

function editor.magiclines(s)
    if s:sub(-1)~="\n" then s=s.."\n" end
    return s:gmatch("(.-)\n")
end

function editor.load()
	font = LG.newFont("fonts/Anonymous.ttf")
end

function editor.update(dt)
	if editor.markerX > editor.lineWidth then
		editor.x = editor.lineWidth - editor.markerX
	else
		editor.x = 0
	end

	if editor.markerY > editor.lineHeight then
		editor.y = editor.lineHeight - editor.markerY
	else
		editor.y = 0
	end

	if timer.get(editor.keyTimer1) >= 0.5 then
		if editor.keyTimer2 == 0 then
			editor.keyTimer2 = timer.newTime()
		end
		if editor.keyTimer2 >= 0.05 then
			if editor.pressedKey == 'backspace' then
				editor.removeCharacter()
			end
			if not editor.saveState then
				if editor.pressedKey == 'delete' then
					editor.removeCharacter(true)
				end
				if editor.pressedKey == 'return' then
					editor.buffer = editor.buffer:utf8sub(0, editor.pos) .. '\n' .. editor.buffer:utf8sub(editor.pos+1)
					editor.moveDown()
					editor.pos = editor.pos + 1
				end
				if editor.pressedKey == 'up' then
					editor.moveUp()
				end
				if editor.pressedKey == 'down' then
					editor.moveDown()
				end
				if editor.pressedKey == 'left' then
					editor.moveLeft()
				end
				if editor.pressedKey == 'right' then
					editor.moveRight()
				end
			end

			editor.keyTimer2 = timer.delete(editor.keyTimer2)
		end
	end
end

function editor.draw()
	LG.setFont(font)

	local drawbuffer = editor.buffer
	local tabs = ''
	for i=1, editor.tabsize do tabs = tabs .. ' ' end
	LG.print(drawbuffer:gsub('\t', tabs), editor.marginX + editor.x*editor.fontwidth, editor.marginY + editor.y*editor.fontheight)
	LG.print('_', editor.marginX + (editor.markerX+editor.x)*editor.fontwidth, editor.marginY + (editor.markerY+editor.y)*editor.fontheight)
	local breakcount = 1

	LG.print(0, editor.marginX - 30, editor.marginY + editor.y*editor.fontheight)
	for i in string.gfind(editor.buffer, '\n') do
		LG.print(breakcount, editor.marginX - 30, editor.marginY + (breakcount+editor.y)*editor.fontheight)
	   	breakcount = breakcount + 1
	end

	if editor.saveState then
		LG.print("Filename:", LW.getWidth()/2 - 200 + 2, 50 - 2 - editor.fontheight)
		LG.rectangle('line', LW.getWidth()/2 - 200, 50, 400, editor.fontheight + 4)
		LG.print(editor.filename, LW.getWidth()/2 - 200 + 2, 50+2)
	end
end

function editor.textinput(t)
	if not editor.saveState then
		editor.buffer = editor.buffer:utf8sub(0, editor.pos) .. t .. editor.buffer:utf8sub(editor.pos+1)
		editor.markerX = editor.markerX + 1
		editor.pos = editor.pos + 1
	else
		editor.filename = editor.filename .. t
	end
end

function editor.keypressed(key)
	if key == 'return' then
		if not editor.saveState then
			editor.buffer = editor.buffer:utf8sub(0, editor.pos) .. '\n' .. editor.buffer:utf8sub(editor.pos+1)
			editor.moveDown()
			editor.keyTimer1 = timer.newTime()
			editor.pressedKey = key
		else
			editor.save()
		end
	elseif key == 'tab' then
		editor.buffer = editor.buffer .. '\t'
		editor.markerX = editor.markerX + 4
		editor.pos = editor.pos + 1
	elseif key == 'backspace' then
		editor.removeCharacter()
		editor.keyTimer1 = timer.newTime()
		editor.pressedKey = key
	elseif key == 'delete' then
		editor.removeCharacter(true)
		editor.keyTimer1 = timer.newTime()
		editor.pressedKey = key
	elseif key == 'up' or key == 'down' or key == 'right' or key == 'left' then
		if key == 'up' then editor.moveUp() end
		if key == 'down' then editor.moveDown() end
		if key == 'left' then editor.moveLeft() end
		if key == 'right' then editor.moveRight() end
		editor.keyTimer1 = timer.newTime()
		editor.pressedKey = key
	elseif key == 's' then
		if LK.isDown('lctrl') then
			editor.saveState = true
		end
	elseif key == 'escape' then
		if editor.saveState then editor.saveState = false end
	end
end

function editor.keyreleased(key)
	for i,v in ipairs(editor.repeatkeys) do
		if key == v then
			editor.keyTimer1 = timer.delete(editor.keyTimer1)
			editor.keyTimer2 = timer.delete(editor.keyTimer2)
			editor.pressedKey = ''
		end
	end
end

function editor.removeCharacter(del)
	if not editor.saveState then
		local function replace_char(pos, str, r)
		    return str:utf8sub(1, pos-1) .. r .. str:utf8sub(pos+1)
		end

		if del ~= true then
			if editor.pos == 0 then return end
			editor.moveLeft()
		end

		if editor.pos >= 0 and editor.pos < editor.buffer:utf8len() then
			last = editor.buffer:utf8sub(editor.pos+1, editor.pos+1)
			editor.buffer = replace_char(editor.pos+1, editor.buffer, '')
		end
	else
		editor.filename = editor.filename:utf8sub(0, -2)
	end
end

function editor.getLine(linenum)
	if linenum == nil then linenum = editor.markerY end
	local i = 0
	for line in editor.magiclines(editor.buffer) do
		if i == linenum then
			return line
		end
		i = i + 1
	end
	return ''
end

function editor.countchars(haystack, needle)
	local i = 0
	for _ in string.gfind(haystack, needle) do
	   i = i + 1
	end
	return i
end

function editor.moveUp()
	local i = editor.markerY - 1
	if i < 0 then i = 0 end
	local prevLine = editor.getLine(i)

	local prevLinesLength = 0
	for line in editor.magiclines(editor.buffer) do
		if prevLinesLength + line:utf8len() + 1 > editor.pos then
			break
		end
		prevLinesLength = prevLinesLength + line:utf8len() + 1
	end

	if prevLine:utf8len() < editor.pos - prevLinesLength then
		editor.pos = prevLinesLength - 1
	else
		if prevLinesLength == 0 then
			editor.pos = 0
		else
			editor.pos = editor.pos - prevLine:utf8len() - 1
		end
	end

	editor.calcPos()
end

function editor.moveDown()
	local prevLinesLength = 0
	for line in editor.magiclines(editor.buffer) do
		if prevLinesLength + line:utf8len() + 1 > editor.pos then
			break
		end
		prevLinesLength = prevLinesLength + line:utf8len() + 1
	end

	if editor.pos - prevLinesLength > editor.getLine(editor.markerY+1):utf8len() then
		if editor.getLine(editor.markerY+1):utf8len() == 0 then
			editor.pos = editor.buffer:utf8len()
		else
			editor.pos = prevLinesLength + editor.getLine():utf8len() + editor.getLine(editor.markerY+1):utf8len() + 1
		end
	else
		editor.pos = editor.pos + editor.getLine():utf8len() + 1
	end	

	editor.calcPos()
end

function editor.moveLeft()
	editor.pos = editor.pos - 1
	if editor.pos < 0 then editor.pos = 0 end
	editor.calcPos()
end

function editor.moveRight()
	editor.pos = editor.pos + 1
	if editor.pos > editor.buffer:utf8len() then editor.pos = editor.buffer:utf8len() end
	editor.calcPos()
end

function editor.calcPos()
	local prevLinesLength = 0
	local t = ''
	for line in editor.magiclines(editor.buffer) do
		if prevLinesLength + line:utf8len() + 1 > editor.pos then
			break
		end
		prevLinesLength = prevLinesLength + line:utf8len() + 1
		t = t .. line
	end

	editor.markerY = editor.countchars(editor.buffer:utf8sub(0,editor.pos), '\n')
	local diff = editor.pos - prevLinesLength
	editor.markerX = diff + editor.countchars(editor.getLine():utf8sub(0,diff), '\t')*(editor.tabsize-1)
end

function editor.save()
	if LF.exists(editor.filename) then
		LF.remove(editor.filename)
	end

	local file = LF.newFile(editor.filename)
	file:open('w')
	file:write(editor.buffer)
	file:close()
	dir = love.filesystem.getSaveDirectory( )

	editor.saveState = false
end

function editor.stealth()
	local mainLoad = love.load
	local mainDraw = love.draw
	local mainKeypressed = love.keypressed
	local mainKeyReleased = love.keyreleased
	local mainUpdate = love.update
	local mainTextInput = love.textinput

	love.load = function ()
		editor.load()
		if mainLoad then mainLoad() end
	end

	love.draw = function ()
		if mainDraw then mainDraw() end
		editor.draw()
	end

	love.textinput = function (t)
		if mainTextInput then mainTextInput(t) end
		editor.textinput(t)
	end

	love.keypressed = function (key)
		editor.keypressed(key)
		if mainKeypressed then mainKeypressed(key) end
	end

	love.keyreleased = function (key)
		editor.keyreleased(key)
		if mainKeyReleased then mainKeyReleased(key) end
	end

	love.update = function (dt)
		editor.update(dt)
		if mainUpdate then mainUpdate(dt) end
	end
end