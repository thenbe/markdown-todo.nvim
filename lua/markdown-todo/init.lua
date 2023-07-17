---@class markdown_todo
local M = {}

-- Repeating characters should be in order of decreasing length.
-- stylua: ignore
local lead_chars = {
	"######", "#####", "####", "###", "##", "#", -- heading
	"-", -- bullet
}

local indicators = {
	undone = {
		literal = " ",
		icon = " ",
		hl = "Delimiter",
	},
	pending = {
		literal = "-",
		hl = "PreProc",
		icon = "󰥔",
	},
	done = {
		literal = "x",
		hl = "String",
		icon = "󰄬",
	},
	on_hold = {
		literal = "=",
		hl = "Special",
		icon = "",
	},
	cancelled = {
		literal = "y",
		hl = "NonText",
		icon = "",
	},
	important = {
		literal = "!",
		hl = "@text.danger",
		icon = "⚠",
	},
	recurring = {
		literal = "+",
		hl = "Repeat",
		icon = "↺",
	},
	ambiguous = {
		literal = "?",
		hl = "Boolean",
		icon = "",
	},
}

-- Helper functions

--- Checks if a line starts with any of the lead characters.
--- Returns the start and end index of the lead character if found, or nil otherwise.
---@param line string
---@return number|nil, number|nil
local function is_lead_char(line)
	for _, lead_char in ipairs(lead_chars) do
		local start, finish = line:find("^%s*" .. lead_char)
		if start then
			return start, finish
		end
	end
	return nil, nil
end

--- Checks if a line already contains a todo indicator.
--- Returns the index of the todo indicator if found, or nil otherwise.
---@param line string
---@return number|nil
local function has_todo_indicator(line)
	return line:find("%(%s?[%s%-_=xy!+?]%s?%)")
end

--- Adds a new todo indicator to a line.
--- Returns the modified line.
---@param line string
---@param itemType TodoItemType
---@return string
local function add_todo_indicator(line, itemType)
	local start, finish = is_lead_char(line)
	if start then
		line = line:sub(1, finish) .. " (" .. indicators[itemType].literal .. ")" .. line:sub(finish + 1)
	end
	return line
end

--- Replaces an existing todo indicator with a new one.
--- Returns the modified line.
---@param line string
---@param itemType TodoItemType
---@return string
local function update_todo_indicator(line, itemType)
	local todo_indicator_index = has_todo_indicator(line)
	if todo_indicator_index then
		line = line:sub(1, todo_indicator_index - 1)
			.. "("
			.. indicators[itemType].literal
			.. ")"
			.. line:sub(todo_indicator_index + 3)
	end
	return line
end

local ns_id = vim.api.nvim_create_namespace("markdown-todo")

--- Sets a virtual icon for a todo indicator, replacing the existing one if any.
---@param indicator_index number
---@param itemType TodoItemType
local set_virtual_icon = function(indicator_index, itemType)
	local line_num = vim.fn.line(".")
	-- clear existing extmarks
	vim.api.nvim_buf_clear_namespace(0, ns_id, line_num, line_num + 1)
	vim.api.nvim_buf_set_extmark(0, ns_id, line_num - 1, indicator_index, {
		-- virt_text = { { indicators[itemType].icon, indicators[itemType].hl } },
		virt_text = { { indicators[itemType].icon } },
		hl_mode = "combine",
		virt_text_pos = "overlay",
	})
end

-- Binds keys to current buffer only.
local function bind_keys()
	-- stylua: ignore start
	vim.keymap.set("n", "<leader>tu", function() require("markdown-todo").make_todo("undone") end, { buffer = 0, desc = "Mark as Undone" })
	vim.keymap.set("n", "<leader>tp", function() require("markdown-todo").make_todo("pending") end, { buffer = 0, desc = "Mark as Pending" })
	vim.keymap.set("n", "<leader>td", function() require("markdown-todo").make_todo("done") end, { buffer = 0, desc = "Mark as Done" })
	vim.keymap.set("n", "<leader>th", function() require("markdown-todo").make_todo("on_hold") end, { buffer = 0, desc = "Mark as On Hold" })
	vim.keymap.set("n", "<leader>tc", function() require("markdown-todo").make_todo("cancelled") end, { buffer = 0, desc = "Mark as Cancelled" })
	vim.keymap.set("n", "<leader>ti", function() require("markdown-todo").make_todo("important") end, { buffer = 0, desc = "Mark as Important" })
	vim.keymap.set("n", "<leader>tr", function() require("markdown-todo").make_todo("recurring") end, { buffer = 0, desc = "Mark as Recurring" })
	vim.keymap.set("n", "<leader>ta", function() require("markdown-todo").make_todo("ambiguous") end, { buffer = 0, desc = "Mark as Ambiguous" })
	-- stylua: ignore end
end

local function set_hl()
	for _, indicator in pairs(indicators) do
		-- use \V for very nomagic (literal) matching
		vim.fn.matchadd(indicator.hl, "(\\V" .. indicator.literal .. ")")
	end
end

local function augroup(name)
	return vim.api.nvim_create_augroup("markdown-todo_" .. name, { clear = true })
end

-- Public function

--- Main function that will be called when a key mapping is used.
--- Retrieves the current line, checks if it starts with a lead character,
--- and if it does, checks if it already contains a todo indicator.
--- If it does, it calls `update_todo_indicator` to replace the existing indicator with a new one.
--- If it doesn't, it calls `add_todo_indicator` to add a new indicator.
--- Returns true if the line was successfully converted into a todo item, or false otherwise.
---@param itemType TodoItemType
---@return boolean
function M.make_todo(itemType)
	local line = vim.api.nvim_get_current_line()
	local start = is_lead_char(line)
	if start then
		if has_todo_indicator(line) then
			line = update_todo_indicator(line, itemType)
		else
			line = add_todo_indicator(line, itemType)
		end
		vim.api.nvim_set_current_line(line)
		local indicator_index = has_todo_indicator(line)
		if not indicator_index then
			vim.api.nvim_err_writeln("Failed to add todo indicator")
			return false
		end
		set_virtual_icon(indicator_index, itemType)
		return true
	else
		return false
	end
end

function M.setup()
	-- BufWinEnter captures first window. WinEnter captures the rest.
	vim.api.nvim_create_autocmd({ "BufWinEnter", "WinEnter" }, {
		group = augroup("set_hl"),
		pattern = { "*.md" },
		callback = set_hl,
	})

	-- bind keys for markdown files only
	vim.api.nvim_create_autocmd("BufEnter", {
		group = augroup("bind_keys"),
		pattern = { "*.md" },
		callback = bind_keys,
	})
end

return M
