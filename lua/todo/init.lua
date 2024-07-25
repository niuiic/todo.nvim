local static = require("todo.static")
local find = require("todo.find")
local search = require("todo.search")
local core = require("core")

-- ~ setup
local function setup(new_config)
	static.config = vim.tbl_deep_extend("force", static.config, new_config or {})
end

local on_err = function(err)
	vim.notify(err, vim.log.levels.ERROR, {
		title = "todo.nvim",
	})
end

-- ~ search_all
---@param filter (fun(todo: todo.Todo): boolean) | nil
local function search_all(filter)
	find(static.config.root_dir(), static.config.rg_pattern, false, function(todos)
		local items = {}
		core.lua.table.each(todos, function(_, todo)
			if filter and filter(todo) == false then
				return
			end
			table.insert(items, {
				label = todo.content,
				lnum = todo.lnum,
				path = todo.path,
				todo = todo,
			})
		end)

		if #items == 0 then
			vim.notify("no todo found", vim.log.levels.INFO, {
				title = "todo.nvim",
			})
			return
		end
		search.telescope_search(items)
	end, on_err)
end

-- ~ search_upstream
---@param filter (fun(todo: todo.Todo): boolean) | nil
local search_upstream = function(filter)
	local lnum = vim.api.nvim_win_get_cursor(0)[1]
	local line = vim.api.nvim_buf_get_lines(0, lnum - 1, lnum, false)[1]
	local todo = static.config.parse(line)
	if not todo then
		vim.notify("not a valid todo", vim.log.levels.WARN, {
			title = "todo.nvim",
		})
		return
	end
	if #todo.dependencies == 0 then
		vim.notify("no upstream todo found", vim.log.levels.INFO, {
			title = "todo.nvim",
		})
		return
	end

	find(static.config.root_dir(), static.config.rg_pattern, false, function(todos)
		local items = {}
		core.lua.list.each(todo.dependencies, function(dep)
			local target = todos[dep]
			if not target then
				return
			end
			if filter and filter(target) == false then
				return
			end

			table.insert(items, {
				label = target.content,
				lnum = target.lnum,
				path = target.path,
				todo = target,
			})
		end)

		if #items == 0 then
			vim.notify("no upstream todo found", vim.log.levels.INFO, {
				title = "todo.nvim",
			})
			return
		end

		search.telescope_search(items)
	end, on_err)
end

-- ~ search_downstream
---@param filter (fun(todo: todo.Todo): boolean) | nil
local search_downstream = function(filter)
	local lnum = vim.api.nvim_win_get_cursor(0)[1]
	local line = vim.api.nvim_buf_get_lines(0, lnum - 1, lnum, false)[1]
	local todo = static.config.parse(line)
	if not todo then
		vim.notify("not a valid todo", vim.log.levels.WARN, {
			title = "todo.nvim",
		})
		return
	end

	find(static.config.root_dir(), static.config.rg_pattern, false, function(todos)
		local items = {}
		core.lua.table.each(todos, function(_, x)
			if not core.lua.list.includes(x.dependencies, function(y)
				return y == todo.id
			end) then
				return
			end
			if filter and filter(x) == false then
				return
			end

			table.insert(items, {
				label = x.content,
				lnum = x.lnum,
				path = x.path,
				todo = x,
			})
		end)

		if #items == 0 then
			vim.notify("no downstream todo found", vim.log.levels.INFO, {
				title = "todo.nvim",
			})
			return
		end

		search.telescope_search(items)
	end, on_err)
end

return {
	setup = setup,
	search_all = search_all,
	search_upstream = search_upstream,
	search_downstream = search_downstream,
}
