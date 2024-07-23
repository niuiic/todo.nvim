local core = require("core")

local find = function(script, path, rg_pattern, parse_pattern, groups, on_exit)
	local ok = true
	local output = ""
	local err = ""

	core.job.spawn("python", {
		script,
		path,
		rg_pattern,
		parse_pattern,
		groups,
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
