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

-- ~ get_todo
---@return todo.Todo | nil
local function get_cur_todo()
	local lnum = vim.api.nvim_win_get_cursor(0)[1]
	local line = vim.api.nvim_buf_get_lines(0, lnum - 1, lnum, false)[1]
	return static.config.parse(line)
end

-- ~ search_all
---@param map_items (fun(items: todo.TelescopeSearchItem[]): todo.TelescopeSearchItem[]) | nil
local function search_all(map_items)
	find(static.config.root_dir(), static.config.rg_pattern, false, function(todos)
		local items = {}
		core.lua.table.each(todos, function(_, todo)
			table.insert(items, {
				label = todo.content,
				todo = todo,
			})
		end)

		if map_items then
			items = map_items(items)
		end

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
---@param map_items (fun(items: todo.TelescopeSearchItem[]): todo.TelescopeSearchItem[]) | nil
local search_upstream = function(map_items)
	local todo = get_cur_todo()
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

			table.insert(items, {
				label = target.content,
				todo = target,
			})
		end)

		if map_items then
			items = map_items(items)
		end

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
---@param map_items (fun(items: todo.TelescopeSearchItem[]): todo.TelescopeSearchItem[]) | nil
local search_downstream = function(map_items)
	local todo = get_cur_todo()
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

			table.insert(items, {
				label = x.content,
				todo = x,
			})
		end)

		if map_items then
			items = map_items(items)
		end

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
	get_cur_todo = get_cur_todo,
	search_all = search_all,
	search_upstream = search_upstream,
	search_downstream = search_downstream,
}
