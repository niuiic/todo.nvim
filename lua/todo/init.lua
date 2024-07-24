local static = require("todo.static")
local find = require("todo.find")
local search = require("todo.search")
local core = require("core")

local function hello()
	find("/home/niuiic/Documents/projects/todo.nvim/test/task.md", static.config.rg_pattern, true):thenCall(
		function(res)
			print("DEBUGPRINT[1]: init.lua:8: res=" .. vim.inspect(res))
		end
	)
end

hello()
