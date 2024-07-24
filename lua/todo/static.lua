local config = {
	rg_pattern = [[\[.*\] \(.*\)\{.*\}: .*]],
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
				dependencies = dependencies and vim.split(dependencies, ",") or {},
				tags = tags and vim.split(tags, ",") or {},
				content = content,
			}
		end
	end,
}

return { config = config }
