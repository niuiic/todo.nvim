local static = require("todo.static")
local core = require("core")

---@param path string
---@param on_exit fun(ok: boolean, data: table | string)
local find = function(path, on_exit)
	local ok = true
	local output = ""
	local err = ""

	core.job.spawn("python", {
		static.config.plugin_dir .. "/find.py",
		path,
		static.config.rg_pattern,
		static.config.parse_pattern,
		static.config.groups,
	}, {}, function()
		if ok then
			on_exit(ok, vim.json.decode(output))
		else
			on_exit(ok, err)
		end
	end, function(_, data)
		ok = false
		err = err .. data
	end, function(_, data)
		output = output .. data
	end)
end

return find
