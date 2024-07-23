local static = require("todo.static")
local find = require("todo.find")

local hello = function()
	find("/home/niuiic/Documents/projects/todo.nvim/test", function(_, data)
		print(vim.inspect(data))
	end)
end
