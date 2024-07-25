local core = require("core")
local ui = require("todo.ui")

---@class todo.TelescopeSearchItem
---@field label string
---@field path string
---@field lnum number
---@field todo todo.Todo

local function get_bufnr_list()
	return core.lua.list.filter(vim.api.nvim_list_bufs(), function(bufnr)
		return vim.api.nvim_buf_is_valid(bufnr) and vim.api.nvim_buf_is_loaded(bufnr)
	end)
end

---@param items todo.TelescopeSearchItem[]
---@param opts table | nil
local function telescope_search(items, opts)
	local pickers = require("telescope.pickers")
	local finders = require("telescope.finders")
	local conf = require("telescope.config").values
	local previewers = require("telescope.previewers")
	local actions = require("telescope.actions")
	local action_state = require("telescope.actions.state")
	local winnr = vim.api.nvim_get_current_win()
	opts = opts or {}

	local bufs = {}
	core.lua.list.each(get_bufnr_list(), function(bufnr)
		local file = vim.api.nvim_buf_get_name(bufnr)
		if not file then
			return
		end
		bufs[file] = bufnr
	end)

	pickers
		.new(opts, {
			prompt_title = "todo.nvim: todos",
			finder = finders.new_table(core.lua.list.map(items, function(x)
				return x.label
			end)),
			sorter = conf.generic_sorter(opts),
			previewer = previewers.new_buffer_previewer({
				define_preview = function(self, entry)
					local target = items[entry.index]

					local height = vim.api.nvim_win_get_height(self.state.winid)
					local offset = math.floor(height / 2)
					local start_line
					start_line = target.lnum - offset
					if start_line < 0 then
						start_line = 0
					end
					local end_line = start_line + height

					local lines = vim.fn.readfile(target.path)
					lines = core.lua.list.filter(lines, function(_, i)
						return i >= start_line and i <= end_line
					end)
					local filetype = vim.filetype.match({ filename = target.path })
					vim.api.nvim_set_option_value("filetype", filetype, {
						buf = self.state.bufnr,
					})
					vim.api.nvim_buf_set_lines(self.state.bufnr, 0, -1, false, lines)
					vim.api.nvim_buf_add_highlight(
						self.state.bufnr,
						0,
						"TelescopeSelection",
						target.lnum - start_line - 1,
						0,
						-1
					)
					print(vim.inspect(target.lnum), offset)
					ui.set_extmark(self.state.bufnr, target.lnum >= offset and offset + 1 or target.lnum, target.todo)
				end,
			}),
			attach_mappings = function(prompt_bufnr)
				actions.select_default:replace(function()
					local selection = action_state.get_selected_entry()
					actions.close(prompt_bufnr)
					local target = core.lua.list.find(items, function(x)
						return x.label == selection[1]
					end)
					if not target then
						return
					end

					vim.api.nvim_set_current_win(winnr)
					if bufs[target.path] then
						vim.api.nvim_win_set_buf(winnr, bufs[target.path])
					else
						vim.cmd("e " .. target.path)
					end
					vim.api.nvim_win_set_cursor(winnr, {
						target.lnum,
						0,
					})
				end)
				return true
			end,
		})
		:find()
end

return { telescope_search = telescope_search }
