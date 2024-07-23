local static = require("todo.static")
local find = require("todo.find")

find(
	"/home/niuiic/Documents/projects/todo.nvim/find.py",
	"/home/niuiic/Documents/projects/todo.nvim/test",
	[[\[.*\] \(.*\)\{.*\}: .*]],
	[[.*\[([x\s])\] \(([^:}]+):?([^}]+)?\){([^\(\)]+)}: (.*)]],
	"status,id,dependencies,tags,content",
	function(_, data)
		print(vim.inspect(data))
	end
)
