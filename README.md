# todo.nvim

Simple but powerful todo manager based on text.

[More neovim plugins](https://github.com/niuiic/awesome-neovim-plugins)

## Dependencies

- [niuiic/core.nvim](https://github.com/niuiic/core.nvim)
- [BurntSushi/ripgrep](https://github.com/BurntSushi/ripgrep)

## Usage

<img src="https://github.com/niuiic/assets/blob/main/todo.nvim/decorate.png" />

- features
  - search all todos
    - `require("todo").search_all`
    - `@param filter (fun(todo: todo.Todo): boolean) | nil`
  - search upstream todos
    - `require("todo").search_upstream`
    - `@param filter (fun(todo: todo.Todo): boolean) | nil`
  - search downstream todos
    - `require("todo").search_downstream`
    - `@param filter (fun(todo: todo.Todo): boolean) | nil`
  - custom decorate
  - custom parser
- default format: `[status] (id:dependencies){tags}: content`
  - `dependencies` and `tags` are separated with `,`.
  - `tags` is optional.
  - `status` map
    - " " = "TODO"
    - x = "DONE"
    - v = "VERIFY"
    - w = "WORKING"
    - b = "BLOCKED"

## Config

- class Todo

```lua
---@class todo.Todo
---@field path string
---@field lnum number
---@field status string
---@field id string
---@field dependencies string[]
---@field tags string[]
---@field content string
```

- default config

```lua
local config = {
	---@type fun(): string
	root_dir = function()
		local core = require("core")
		return core.file.root_path()
	end,
	---@type string
	rg_pattern = [[\[.*\] \(.*\)\{.*\}: .*]],
	---@type fun(text: string): todo.Todo | nil
	parse = function(text)
		local status, id, dependencies, tags, content =
			string.match(text, ".*%[([vbwx%s])%] %(([^:]+):([^%)]+)%){([^{}]+)}: (.*)")
		if status == nil then
			status, id, tags, content = string.match(text, ".*%[([vbwx%s])%] %(([^:]+)%){([^{}]+)}: (.*)")
		end
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
			tags ~= "" and { tags, "TodoTag" } or nil,
			dependencies ~= "" and { dependencies, "TodoDependency" } or nil,
		}

		local result = {}
		core.lua.list.each(badges, function(badge)
			table.insert(result, roundStart)
			table.insert(result, badge)
			table.insert(result, roundEnd)
			table.insert(result, space)
		end)
		return result
	end,
}
```
