--[[ Take blizzard tooltip table and conver it into a slash menu, hm.
--
--2 Part process, parse the menu into tokens then generate a slash command
--listing
]]

local slashHandler = function(str)
	local t = { str.spit(" ") }

	for k, v in pairs(t) do
		print(v)
	end
end

local recurse
local recurse = function(table)
	local t = {}

	for k, v in pairs(table) do
		if(v.title) then
			if(v.menuList) then
				t[v.title] = recurse(v.menuList)
			elseif(v.func) then
				t[v.title] = v.func
			end
		end
	end

	return t
end

local makeHelp = function(t)
end

function tooltip2slash(t, name)
	local obj = {
		name = name,
	}

	
end
