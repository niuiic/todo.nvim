local static = require("todo.static")

local function set_hl()
	local bg = vim.api.nvim_get_hl(0, { name = "CursorLine" }).bg

	vim.api.nvim_set_hl(0, "TodoId", {
		fg = "#E0AF68",
		bg = bg,
		italic = true,
	})
	vim.api.nvim_set_hl(0, "TodoStatus", {
		fg = "#0DB9D7",
		bg = bg,
		italic = true,
	})
	vim.api.nvim_set_hl(0, "TodoTag", {
		fg = "#00FFCC",
		bg = bg,
		italic = true,
	})
	vim.api.nvim_set_hl(0, "TodoDependency", {
		fg = "#FF06C1",
		bg = bg,
		italic = true,
	})
	vim.api.nvim_set_hl(0, "TodoRound", {
		fg = bg,
	})
end

---@param bufnr number
---@param lnum number
---@param todo todo.Todo
local function set_extmark(bufnr, lnum, todo)
	vim.api.nvim_buf_set_extmark(bufnr, static.ns_id, lnum - 1, 0, {
		virt_lines = {
			static.config.badges(todo),
		},
		virt_lines_above = true,
	})
end

return { set_hl = set_hl, set_extmark = set_extmark }
