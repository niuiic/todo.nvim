local M = {
	_ns_id = vim.api.nvim_create_namespace("todo"),
	_id_count = 0,
	_sign_group = "TodoSigns",
	_sign_name = "TodoSign",
	---@type {[string]: {[string]: unknown}}
	_signs = {},
}

M.init = function()
	vim.fn.sign_define(M._sign_name, {
		text = "✓",
		texthl = "LineNr",
	})

	vim.api.nvim_create_autocmd("BufWritePost", {
		callback = function(args)
			local file_path = vim.api.nvim_buf_get_name(args.buf)
			local signs = M._get_signs(file_path)
			M._signs[file_path] = signs and signs or nil
		end,
	})

	vim.api.nvim_create_autocmd("BufEnter", {
		callback = function(args)
			local file_path = vim.api.nvim_buf_get_name(args.buf)
			local signs = M._signs[file_path]
			if not signs then
				return
			end

			for lnum, _ in pairs(signs) do
				M._place_sign(args.buf, lnum)
			end
		end,
	})
end

M.toggle_state = function()
	if not M._toggle_state_with_text() then
		M._toggle_state_with_sign()
	end
end

M._toggle_state_with_sign = function()
	local lnum = vim.api.nvim_win_get_cursor(0)[1]
	local bufnr = vim.api.nvim_get_current_buf()
	local signs = M._get_signs(vim.api.nvim_buf_get_name(0)) or {}

	if not signs[tostring(lnum)] then
		M._place_sign(bufnr, lnum)
	else
		vim.fn.sign_unplace(M._sign_group, { id = signs[tostring(lnum)] })
	end
end

M._place_sign = function(bufnr, lnum)
	M._id_count = M._id_count + 1
	vim.fn.sign_place(M._id_count, M._sign_group, M._sign_name, bufnr, {
		lnum = lnum,
		priority = 10,
	})
	local file_path = vim.api.nvim_buf_get_name(bufnr)
	if not M._signs[file_path] then
		M._signs[file_path] = {}
	end
	M._signs[file_path][tostring(lnum)] = true
end

M._get_signs = function(file_path)
	local signs = (vim.fn.sign_getplaced(file_path, {
		group = M._sign_group,
	})[1] or {}).signs

	if not signs then
		return
	end

	local results = {}
	for _, sign in ipairs(signs) do
		if sign.name == M._sign_name then
			results[tostring(sign.lnum)] = sign.id
		end
	end

	return results
end

---@return boolean
M._toggle_state_with_text = function()
	local lnum = vim.api.nvim_win_get_cursor(0)[1]
	local line = vim.api.nvim_buf_get_lines(0, lnum - 1, lnum, false)[1]

	if line:find("@end") then
		local space, todo = line:match("^([%s]*)- %[.*%] (.+) @start%(.*%).*$")
		if not todo then
			return false
		end

		vim.api.nvim_buf_set_lines(0, lnum - 1, lnum, false, {
			string.format("%s- %s", space, todo),
		})
		return true
	end

	if line:find("@start") then
		local space, todo, start_time = line:match("^([%s]*)- %[.*%] (.+) @start%((.+)%)$")
		if not todo or not start_time then
			return false
		end

		local start_timestamp = require("omega").get_timestamp(start_time)
		local end_timestamp = require("omega").get_timestamp()

		local duration = require("omega").get_human_readable_duration(start_timestamp, end_timestamp)

		vim.api.nvim_buf_set_lines(0, lnum - 1, lnum, false, {
			string.format(
				"%s- [x] %s @start(%s) @end(%s) @last(%s)",
				space,
				todo,
				start_time,
				os.date("%Y-%m-%d %H:%M:%S"),
				duration
			),
		})
		return true
	end

	local space, todo = line:match("^([%s]*)- (.+)$")
	if not todo then
		return false
	end

	vim.api.nvim_buf_set_lines(0, lnum - 1, lnum, false, {
		string.format("%s- [ ] %s @start(%s)", space, todo, os.date("%Y-%m-%d %H:%M:%S")),
	})
	return true
end

M.store = function(file_path)
	local info = {
		signs = M._signs,
		id_count = M._id_count,
	}
	local text = vim.json.encode(info)
	vim.fn.writefile({ text }, file_path)
end

M.restore = function(file_path)
	local text = vim.fn.readfile(file_path)[1]
	local info = vim.json.decode(text)
	M._signs = info.signs or {}
	M._id_count = info.id_count or 0
end

M.init()

return M
