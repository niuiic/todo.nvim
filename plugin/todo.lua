local find = require("todo.find")
local static = require("todo.static")
local core = require("core")
local ui = require("todo.ui")

ui.set_hl()

vim.api.nvim_create_autocmd({ "BufReadPost", "BufWritePost" }, {
	callback = function(args)
		find(vim.api.nvim_buf_get_name(args.buf), static.config.rg_pattern, true, function(todos)
			core.lua.table.each(todos, function(_, todo)
				ui.set_extmark(args.buf, todo.lnum, todo)
			end)
		end, function() end)
	end,
})
