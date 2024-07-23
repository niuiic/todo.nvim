local config = {
	plugin_dir = vim.fn.stdpath("data") .. "/lazy/todo.nvim",
	rg_pattern = [[\[.*\] \(.*\)\{.*\}: .*]],
	parse_pattern = [[.*\[([x\s])\] \(([^:}]+):?([^}]+)?\){([^\(\)]+)}: (.*)]],
	groups = "status,id,dependencies,tags,content",
}

return { config = config }
