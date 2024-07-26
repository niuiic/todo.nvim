---@class todo.Todo
---@field path string
---@field lnum number
---@field status string
---@field id string
---@field dependencies string[]
---@field tags string[]
---@field content string

local config = {
	---@type fun(): string
	root_dir = function()
		local core = require("core")
		return core.file.root_path()
	end,
	---@type string
	rg_pattern = [[\[.+\] \(.+\)\{?.*\}?: .*]],
	---@type fun(text: string): todo.Todo | nil
	parse = function(text)
		local status, id, dependencies, tags, content =
			string.match(text, "^.*%[([vbwx%s])%] %(([^:]+):?([^%)]*)%){?([^{}]*)}?: (.*)$")
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
	---@type fun(todo: todo.Todo): [string, string][]
	badges = function(todo)
		local core = require("core")

		local tags = core.lua.list.reduce(todo.tags, function(prev, tag)
			return prev == "" and tag or prev .. "," .. tag
		end, "")

		local dependencies = core.lua.list.reduce(todo.dependencies, function(prev, dep)
			return prev == "" and dep or prev .. "," .. dep
		end, "")

		local roundStart = { "", "TodoRound" }
		local roundEnd = { "", "TodoRound" }
		local space = { " ", "TodoSpace" }

		local badges = {
			{ todo.id, "TodoId" },
			{ "" .. todo.status .. "", "TodoStatus" },
			{ tags, "TodoTag" },
			{ dependencies, "TodoDependency" },
		}

		local result = {}
		core.lua.list.each(badges, function(badge)
			if badge[1] ~= "" then
				table.insert(result, roundStart)
				table.insert(result, badge)
				table.insert(result, roundEnd)
				table.insert(result, space)
			end
		end)
		return result
	end,
}

local ns_id = vim.api.nvim_create_namespace("todo.nvim")

return { config = config, ns_id = ns_id }
