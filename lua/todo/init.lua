local static = require("todo.static")
local find = require("todo.find")
local search = require("todo.search")
local core = require("core")

local hello = function()
	find("/home/niuiic/Documents/projects/todo.nvim/test/task2.md", function(ok, data)
		if ok then
			local items = core.lua.list.map(data, function(x)
				return {
					label = x.path .. ": " .. x.content,
					lnum = x.lnum,
					path = x.path,
				}
			end)
			search(items)
		end
	end)
end

-- hello()
