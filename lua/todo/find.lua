local static = require("todo.static")
local core = require("core")

---@param rg_pattern string
---@param path string
---@param search_file boolean
---@param on_ok fun(todos: {[string]: todo.Todo})
---@param on_err fun(reason: string)
local function find(path, rg_pattern, search_file, on_ok, on_err)
	if not core.file.file_or_dir_exists(path) then
		on_err(path .. " does not exist")
		return
	end

	local output = ""
	local err = ""
	local on_exit = function(code)
		if code ~= 0 and err ~= "" then
			on_err(err)
			return
		end

		local lines = core.lua.string.split(output, "\n")

		local todos = {}
		if search_file then
			local pattern = "^([%d]+):(.*)$"
			for _, line in ipairs(lines) do
				local lnum, text = string.match(line, pattern)
				if lnum ~= nil then
					local todo = static.config.parse(text)
					if type(todo) == "table" then
						todo.path = path
						todo.lnum = tonumber(lnum) or -1
						if todos[todo.id] ~= nil then
							vim.notify("duplicate todo found: " .. todo.id, vim.log.levels.ERROR, {
								title = "todo.nvim",
							})
							return
						end
						todos[todo.id] = todo
					end
				end
			end
		else
			local pattern = "^([^:]+):([%d]+):(.*)$"
			for _, line in ipairs(lines) do
				local file, lnum, text = string.match(line, pattern)
				if file ~= nil then
					local todo = static.config.parse(text)
					if type(todo) == "table" then
						todo.path = file
						todo.lnum = tonumber(lnum) or -1
						if todos[todo.id] ~= nil then
							vim.notify("duplicate todo found: " .. todo.id, vim.log.levels.ERROR, {
								title = "todo.nvim",
							})
							return
						end
						todos[todo.id] = todo
					end
				end
			end
		end

		on_ok(todos)
	end

	core.job.spawn(
		"rg",
		{
			rg_pattern,
			"--line-number",
			path,
		},
		{},
		on_exit,
		function(_, data)
			err = err .. data
		end,
		function(_, data)
			output = output .. data
		end
	)
end

return find
