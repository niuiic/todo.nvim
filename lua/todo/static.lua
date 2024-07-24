local config = {
	plugin_dir = vim.fn.stdpath("data") .. "/lazy/todo.nvim",
	rg_pattern = [[\[.*\] \(.*\)\{.*\}: .*]],
	parse_pattern = [[.*\[([x\s])\] \(([^:}]+):?([^}]+)?\){([^\(\)]+)}: (.*)]],
	parse = function(text)
		local status, id, dependencies, tags, content =
			string.match(text, ".*%[([vbwx%s])%] %(([^:]+):([^%)]+)%){([^{}]+)}: (.*)")
		if status == nil then
			status, id, tags, content = string.match(text, ".*%[([vbwx%s])%] %(([^:]+)%){([^{}]+)}: (.*)")
		end
		if status ~= nil then
			local status_map = {
				[" "] = "TODO",
				x = "DONE",
				v = "VERIFY",
				w = "WORKING",
				b = "BLOCKED",
			}
			return {
				status = status_map[status],
				id = id,
				dependencies = dependencies and vim.split(dependencies, ",") or nil,
				tags = tags,
				content = content,
			}
		end
	end,
	groups = "status,id,dependencies,tags,content",
}

return { config = config }
