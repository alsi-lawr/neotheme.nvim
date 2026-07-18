local palette = require("neotheme.palette")
local simplified = require("neotheme.themes.simplified")

local M = {}
local family_version = 1
local theme_version = 2
local slug_pattern = "^[a-z0-9]+[a-z0-9-]*$"

local function copy(value)
	if type(value) ~= "table" then
		return value
	end
	local result = {}
	for key, item in pairs(value) do
		result[key] = copy(item)
	end
	return result
end

local function state_root()
	return vim.fs.joinpath(vim.fn.stdpath("state"), "neotheme")
end

local function family_path(name)
	return vim.fs.joinpath(state_root(), "families", name .. ".json")
end

local function theme_path(family, name)
	return vim.fs.joinpath(state_root(), "palettes", family, name .. ".json")
end

local function is_slug(value)
	return type(value) == "string" and value:match(slug_pattern) ~= nil
end

local function keys_are(record, expected)
	for key in pairs(record) do
		if not expected[key] then
			return false, "unknown field " .. tostring(key)
		end
	end
	for key in pairs(expected) do
		if record[key] == nil then
			return false, "missing field " .. key
		end
	end
	return true
end

local function validate_family(record, path_name)
	if type(record) ~= "table" then
		return nil, "record must be an object"
	end
	local valid, message = keys_are(record, { version = true, name = true, enabled = true })
	if not valid then
		return nil, message
	end
	if record.version ~= family_version then
		return nil, "unsupported version"
	end
	if not is_slug(record.name) then
		return nil, "name must be a lowercase ASCII slug"
	end
	if record.name ~= path_name then
		return nil, "name does not match the file name"
	end
	if type(record.enabled) ~= "boolean" then
		return nil, "enabled must be a boolean"
	end
	return record
end

local function validate_theme(record, path_family, path_name)
	if type(record) ~= "table" then
		return nil, "record must be an object"
	end
	local expected = {
		version = true,
		family = true,
		name = true,
		background = true,
		palette = true,
	}
	if record.version == theme_version then
		expected.mode = true
	end
	local valid, message = keys_are(record, expected)
	if not valid then
		return nil, message
	end
	if record.version ~= 1 and record.version ~= theme_version then
		return nil, "unsupported version"
	end
	if not is_slug(record.family) or not is_slug(record.name) then
		return nil, "family and name must be lowercase ASCII slugs"
	end
	if record.name == "custom" then
		return nil, "name custom is reserved"
	end
	if record.family ~= path_family or record.name ~= path_name then
		return nil, "family or name does not match the file path"
	end
	if record.background ~= "dark" and record.background ~= "light" then
		return nil, "background must be dark or light"
	end
	local mode = record.version == 1 and "full" or record.mode
	if mode ~= "simplified" and mode ~= "full" then
		return nil, "mode must be simplified or full"
	end
	local complete, palette_error
	if mode == "simplified" then
		complete, palette_error = simplified.is_complete(record.palette)
	else
		complete, palette_error = palette.is_complete(record.palette)
	end
	if not complete then
		return nil, palette_error
	end
	local normalized = copy(record)
	normalized.mode = mode
	return normalized
end

local function decode(path)
	local read_ok, lines_or_error = pcall(vim.fn.readfile, path)
	if not read_ok then
		return nil, "failed to read JSON: " .. tostring(lines_or_error)
	end
	if type(lines_or_error) ~= "table" then
		return nil, "failed to read JSON"
	end
	local ok, value = pcall(vim.json.decode, table.concat(lines_or_error, "\n"))
	if not ok then
		return nil, "invalid JSON: " .. tostring(value)
	end
	return value
end

local function scan(directory, callback)
	local handle = vim.uv.fs_scandir(directory)
	if not handle then
		return
	end
	local entries = {}
	while true do
		local name, kind = vim.uv.fs_scandir_next(handle)
		if not name then
			break
		end
		table.insert(entries, { name = name, kind = kind })
	end
	table.sort(entries, function(left, right)
		return left.name < right.name
	end)
	for _, entry in ipairs(entries) do
		callback(entry.name, entry.kind)
	end
end

---@return table inventory
function M.load()
	local result = { families = {}, themes = {}, diagnostics = {} }
	local theme_sources = {}
	local duplicate_names = {}
	local families_directory = vim.fs.joinpath(state_root(), "families")
	scan(families_directory, function(file, kind)
		if kind ~= "file" or not file:match("%.json$") then
			return
		end
		local name = file:sub(1, -6)
		local path = vim.fs.joinpath(families_directory, file)
		local decoded, decode_error = decode(path)
		local record, validation_error
		if decoded then
			record, validation_error = validate_family(decoded, name)
		else
			validation_error = decode_error
		end
		if record then
			result.families[name] = record
		else
			table.insert(
				result.diagnostics,
				"families/" .. file .. ": " .. tostring(validation_error)
			)
		end
	end)

	local palettes_directory = vim.fs.joinpath(state_root(), "palettes")
	scan(palettes_directory, function(family, kind)
		if kind ~= "directory" then
			return
		end
		local directory = vim.fs.joinpath(palettes_directory, family)
		scan(directory, function(file, file_kind)
			if file_kind ~= "file" or not file:match("%.json$") then
				return
			end
			local name = file:sub(1, -6)
			local decoded, decode_error = decode(vim.fs.joinpath(directory, file))
			local record, validation_error
			if decoded then
				record, validation_error = validate_theme(decoded, family, name)
			else
				validation_error = decode_error
			end
			if record then
				local relative_path = "palettes/" .. family .. "/" .. file
				if duplicate_names[name] then
					table.insert(
						result.diagnostics,
						relative_path .. ": name is not globally unique"
					)
				elseif theme_sources[name] then
					table.insert(
						result.diagnostics,
						theme_sources[name] .. ": name is not globally unique"
					)
					table.insert(
						result.diagnostics,
						relative_path .. ": name is not globally unique"
					)
					result.themes[name] = nil
					duplicate_names[name] = true
				else
					result.themes[name] = record
					theme_sources[name] = relative_path
				end
			else
				table.insert(
					result.diagnostics,
					"palettes/" .. family .. "/" .. file .. ": " .. tostring(validation_error)
				)
			end
		end)
	end)
	table.sort(result.diagnostics)
	return result
end

local function write_atomic(path, record)
	vim.fn.mkdir(vim.fs.dirname(path), "p")
	local temporary = path
		.. ".tmp-"
		.. tostring(vim.uv.os_getpid())
		.. "-"
		.. tostring(vim.loop.hrtime())
	local ok, write_error =
		pcall(vim.fn.writefile, vim.split(vim.json.encode(record), "\n"), temporary)
	if not ok then
		error("neotheme: failed to write palette state: " .. tostring(write_error), 2)
	end
	local renamed, rename_error = vim.uv.fs_rename(temporary, path)
	if not renamed then
		pcall(vim.fn.delete, temporary)
		error("neotheme: failed to atomically save palette state: " .. tostring(rename_error), 2)
	end
end

local function require_slug(value, label)
	if not is_slug(value) then
		error("neotheme: invalid " .. label .. ": expected a lowercase ASCII slug", 3)
	end
end

local function delete_file(path, label)
	if not vim.uv.fs_stat(path) then
		error("neotheme: " .. label .. " does not exist", 3)
	end
	local deleted, delete_error = vim.uv.fs_unlink(path)
	if not deleted then
		error("neotheme: failed to delete " .. label .. ": " .. tostring(delete_error), 3)
	end
end

local function filesystem_error(message, code)
	if type(code) == "string" and code ~= "" then
		return code
	end
	if type(message) == "string" and message ~= "" then
		return message
	end
	return "unknown filesystem error"
end

local function family_inspection_error(name, operation, message, code)
	error(
		"neotheme: cannot verify that family '"
			.. name
			.. "' is empty: failed to "
			.. operation
			.. " palettes/"
			.. name
			.. " ("
			.. filesystem_error(message, code)
			.. "); fix directory access and retry",
		3
	)
end

---@param name string
---@param enabled boolean
function M.write_family(name, enabled)
	local record, message =
		validate_family({ version = family_version, name = name, enabled = enabled }, name)
	if not record then
		error("neotheme: invalid family state: " .. tostring(message), 2)
	end
	write_atomic(family_path(name), record)
end

local function prepare_theme_write(record)
	local candidate = copy(record)
	if candidate.version ~= 1 and candidate.version ~= theme_version then
		return nil, "unsupported version"
	end
	if candidate.version == 1 then
		if candidate.mode ~= nil and candidate.mode ~= "full" then
			return nil, "version 1 palette state must be mode-less or full"
		end
		candidate.mode = "full"
	end
	candidate.version = theme_version
	return candidate
end

---@param record table
function M.write_theme(record)
	local candidate, preparation_error = prepare_theme_write(record)
	if not candidate then
		error("neotheme: invalid palette state: " .. preparation_error, 2)
	end
	local valid, message = validate_theme(candidate, candidate.family, candidate.name)
	if not valid then
		error("neotheme: invalid palette state: " .. tostring(message), 2)
	end
	write_atomic(theme_path(record.family, record.name), valid)
	return copy(valid)
end

---@param name string
function M.delete_family(name)
	require_slug(name, "family name")
	delete_file(family_path(name), "family state '" .. name .. "'")
end

---@param family string
---@param name string
function M.delete_theme(family, name)
	require_slug(family, "family name")
	require_slug(name, "theme name")
	delete_file(theme_path(family, name), "palette state '" .. family .. "/" .. name .. "'")
end

---@param name string
---@return boolean
function M.family_has_theme_files(name)
	require_slug(name, "family name")
	local directory = vim.fs.joinpath(state_root(), "palettes", name)
	local metadata, stat_error, stat_code = vim.uv.fs_stat(directory)
	if metadata == nil then
		if stat_code == "ENOENT" or tostring(stat_error):find("ENOENT", 1, true) then
			return false
		end
		family_inspection_error(name, "inspect", stat_error, stat_code)
	end
	if metadata.type ~= "directory" then
		error(
			"neotheme: cannot verify that family '"
				.. name
				.. "' is empty: palettes/"
				.. name
				.. " is not a directory; repair or remove it and retry",
			3
		)
	end

	local handle, scan_error, scan_code = vim.uv.fs_scandir(directory)
	if not handle then
		family_inspection_error(name, "scan", scan_error, scan_code)
	end
	local next_ok, entry, next_error, next_code = pcall(vim.uv.fs_scandir_next, handle)
	if not next_ok then
		family_inspection_error(name, "scan", entry, nil)
	end
	if entry == nil and next_error ~= nil then
		family_inspection_error(name, "scan", next_error, next_code)
	end
	return entry ~= nil
end

---@param record table
---@return boolean valid
---@return string? error_message
function M.valid_theme(record)
	if type(record) ~= "table" then
		return false, "record must be an object"
	end
	local candidate, preparation_error = prepare_theme_write(record)
	if not candidate then
		return false, preparation_error
	end
	local valid, message = validate_theme(candidate, candidate.family, candidate.name)
	return valid ~= nil, message
end

function M.root()
	return state_root()
end

return M
