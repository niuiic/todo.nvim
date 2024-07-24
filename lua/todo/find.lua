local static = require("todo.static")
local core = require("core")
local promise = require("promise")

---@param rg_pattern string
---@param path string
---@param search_file boolean
local function find(path, rg_pattern, search_file)
	return promise:new(function(resolve, reject)
		if not core.file.file_or_dir_exists(path) then
			reject(path .. " does not exist")
			return
		end

		local output = ""
		local err = ""
		local on_exit = function(code)
			if code ~= 0 then
				reject(err)
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
						if todo then
							todo.path = path
							todo.lnum = tonumber(lnum)
							todo.text = text
							table.insert(todos, todo)
						end
					end
				end
			else
				local pattern = "^([^:]+):([%d]+):(.*)$"
				for _, line in ipairs(lines) do
					local file, lnum, text = string.match(line, pattern)
					if file ~= nil then
						local todo = static.config.parse(text)
						if todo then
							todo.path = file
							todo.lnum = tonumber(lnum)
							todo.text = text
							table.insert(todos, todo)
						end
					end
				end
			end

			resolve(todos)
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
	end)
end

return find
