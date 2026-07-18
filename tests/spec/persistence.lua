local h = dofile(NEOTHEME_TEST_ROOT .. "/tests/helpers.lua")
local engine = require("neotheme")
local palette = require("neotheme.palette")
local state = require("neotheme.state")
local themes = require("neotheme.themes")

local function contains(values, expected)
	for _, value in ipairs(values) do
		if value:find(expected, 1, true) then
			return true
		end
	end
	return false
end

local function write_record(family, file, record)
	local directory = vim.fs.joinpath(state.root(), "palettes", family)
	vim.fn.mkdir(directory, "p")
	vim.fn.writefile({ vim.json.encode(record) }, vim.fs.joinpath(directory, file))
end

local function clone_record(family, name)
	return {
		version = 1,
		family = family,
		name = name,
		background = "dark",
		palette = themes.get("gruber-dark"),
	}
end

h.falsy(vim.uv.fs_stat(state.root()), "state root is lazy")
themes.create_family("empty")
h.falsy(vim.tbl_contains(themes.families(), "empty"), "empty user family is not public")
h.eq({}, themes.names("empty"), "empty user family has no public themes")
local all_families, all_themes = themes.inventory()
h.truthy(vim.tbl_contains(all_families, "empty"), "manager inventory keeps empty family")
h.eq({}, all_themes.empty, "empty family remains manageable")

themes.create_family("studio")
themes.create_family("other")
local studio = themes.clone("gruber-dark", "studio", "studio-night")
local other = themes.clone("typeset-paper", "other", "other-paper")
h.eq(2, studio.version, "new state records use schema version 2")
h.eq("full", studio.mode, "bundled cloning creates a full source record")
h.eq(59, #palette.paths(), "palette contract has 59 paths")
h.truthy(vim.tbl_contains(themes.families(), "studio"), "family with a valid theme is public")
h.eq(studio.palette, themes.get("studio-night"), "user palette is exact-lookupable")
h.eq(other.palette, themes.get("other-paper"), "multiple families retain their themes")

local theme_file = vim.fs.joinpath(state.root(), "palettes", "studio", "studio-night.json")
local before = assert(io.open(theme_file, "r")):read("*a")
studio.palette.ui.accent = "#112233"
themes.save(studio)
local after = assert(io.open(theme_file, "r")):read("*a")
h.falsy(before == after, "saving replaces the prior record")
local scan = vim.uv.fs_scandir(vim.fs.dirname(theme_file))
while scan do
	local file = vim.uv.fs_scandir_next(scan)
	if not file then
		break
	end
	h.falsy(file:find(".tmp-", 1, true), "atomic write leaves no temporary record")
end

themes.set_family_enabled("studio", false)
h.falsy(vim.tbl_contains(themes.families(), "studio"), "disabled family is hidden publicly")
h.eq(studio.palette, themes.get("studio-night"), "disabled theme remains exact-lookupable")
engine.switch("studio-night")
h.eq("studio-night", engine.current().active_theme, "disabled theme remains switchable")
themes.set_family_enabled("studio", true)

local active_bytes = assert(io.open(theme_file, "r")):read("*a")
h.falsy(pcall(themes.delete_theme, "studio-night"), "active user theme cannot be deleted")
h.eq(active_bytes, assert(io.open(theme_file, "r")):read("*a"), "active rejection preserves bytes")

local configured = themes.clone("gruber-dark", "other", "configured-palette")
local configured_file =
	vim.fs.joinpath(state.root(), "palettes", configured.family, configured.name .. ".json")
engine.setup({ theme = configured.name })
local configured_bytes = assert(io.open(configured_file, "r")):read("*a")
h.falsy(pcall(themes.delete_theme, configured.name), "configured user theme cannot be deleted")
h.eq(
	configured_bytes,
	assert(io.open(configured_file, "r")):read("*a"),
	"configured rejection preserves bytes"
)
engine.setup({ theme = "gruber-dark-muted" })
themes.delete_theme(configured.name)
h.falsy(vim.uv.fs_stat(configured_file), "unconfigured inactive user theme can be deleted")

h.falsy(pcall(themes.delete_theme, "gruber-dark"), "bundled theme cannot be deleted")
h.falsy(pcall(themes.delete_family, "studio"), "non-empty user family cannot be deleted")

themes.create_family("scan-failure")
themes.clone("gruber-dark", "scan-failure", "scan-failure-theme")
local scan_family_file = vim.fs.joinpath(state.root(), "families", "scan-failure.json")
local scan_theme_directory = vim.fs.joinpath(state.root(), "palettes", "scan-failure")
local scan_theme_file = vim.fs.joinpath(scan_theme_directory, "scan-failure-theme.json")
local scan_family_bytes = assert(io.open(scan_family_file, "r")):read("*a")
local scan_theme_bytes = assert(io.open(scan_theme_file, "r")):read("*a")
local original_scandir = vim.uv.fs_scandir
vim.uv.fs_scandir = function(directory)
	if directory == scan_theme_directory then
		return nil, "permission denied", "EACCES"
	end
	return original_scandir(directory)
end
local scan_delete_ok, scan_delete_error = pcall(themes.delete_family, "scan-failure")
vim.uv.fs_scandir = original_scandir
h.falsy(scan_delete_ok, "palette directory scan failure blocks family deletion")
h.truthy(
	tostring(scan_delete_error):find(
		"cannot verify that family 'scan-failure' is empty: failed to scan palettes/scan-failure (EACCES); fix directory access and retry",
		1,
		true
	),
	"scan failure reports a deterministic actionable error"
)
h.eq(
	scan_family_bytes,
	assert(io.open(scan_family_file, "r")):read("*a"),
	"scan failure preserves family metadata bytes"
)
h.eq(
	scan_theme_bytes,
	assert(io.open(scan_theme_file, "r")):read("*a"),
	"scan failure preserves palette bytes"
)
h.truthy(themes.is_user("scan-failure-theme"), "scan failure preserves palette inventory")

themes.set_family_enabled("gruber", false)
h.falsy(themes.is_user_family("gruber"), "bundled visibility state remains bundled")
h.falsy(pcall(themes.delete_family, "gruber"), "bundled family cannot be deleted")
themes.set_family_enabled("gruber", true)

themes.create_family("disposable")
local disposable_family = vim.fs.joinpath(state.root(), "families", "disposable.json")
h.truthy(vim.uv.fs_stat(disposable_family), "empty user family has exact state path")
themes.delete_family("disposable")
h.falsy(vim.uv.fs_stat(disposable_family), "empty user family can be deleted")

for _, unsafe in ipairs({ "../studio", "/tmp/studio", "studio/theme", "Studio" }) do
	h.falsy(pcall(state.delete_family, unsafe), "family deletion rejects unsafe path: " .. unsafe)
end
for _, unsafe in ipairs({ "../studio-night", "/tmp/theme", "studio/theme", "StudioNight" }) do
	h.falsy(
		pcall(state.delete_theme, "studio", unsafe),
		"theme deletion rejects unsafe path: " .. unsafe
	)
end
h.falsy(
	pcall(state.delete_theme, "../studio", "studio-night"),
	"theme deletion rejects unsafe family path"
)
h.truthy(vim.uv.fs_stat(theme_file), "unsafe deletion attempts preserve the valid palette")

h.falsy(
	pcall(
		themes.create_snapshot,
		{ background = "dark", palette = palette.empty() },
		"other",
		"incomplete"
	),
	"snapshot creation retains strict complete-palette validation"
)
h.falsy(
	vim.uv.fs_stat(vim.fs.joinpath(state.root(), "palettes", "other", "incomplete.json")),
	"invalid snapshot creation does not persist a record"
)

for _, attempt in ipairs({
	{ name = "custom", label = "reserved custom" },
	{ name = "gruber-dark", label = "bundled collision" },
	{ name = "studio-night", label = "user collision" },
}) do
	local ok = pcall(themes.clone, "gruber-dark", "studio", attempt.name)
	h.falsy(ok, attempt.label .. " is rejected")
end

write_record(
	"studio",
	"unknown.json",
	vim.tbl_extend("force", clone_record("studio", "unknown"), {
		extra = true,
	})
)
write_record(
	"studio",
	"unsupported.json",
	vim.tbl_extend("force", clone_record("studio", "unsupported"), {
		version = 3,
	})
)
write_record("studio", "bad-slug.json", clone_record("studio", "BadSlug"))
write_record("studio", "wrong-path.json", clone_record("studio", "different-name"))
write_record("studio", "custom.json", clone_record("studio", "custom"))
write_record("studio", "broken.json", { invalid = true })
write_record("other", "studio-night.json", clone_record("other", "studio-night"))
write_record("other", "gruber-dark.json", clone_record("other", "gruber-dark"))
local unreadable = vim.fs.joinpath(state.root(), "palettes", "other", "unreadable.json")
vim.fn.writefile({ vim.json.encode(clone_record("other", "unreadable")) }, unreadable)

local original_readfile = vim.fn.readfile
vim.fn.readfile = function(path)
	if path == unreadable then
		error("deliberate read failure")
	end
	return original_readfile(path)
end
local inventory = state.load()
vim.fn.readfile = original_readfile
local sorted = vim.deepcopy(inventory.diagnostics)
table.sort(sorted)
h.eq(sorted, inventory.diagnostics, "state diagnostics are deterministic and sorted")
h.truthy(
	contains(inventory.diagnostics, "unknown.json: unknown field extra"),
	"unknown schema is isolated"
)
h.truthy(
	contains(inventory.diagnostics, "unsupported.json: unsupported version"),
	"unknown version is isolated"
)
h.truthy(
	contains(inventory.diagnostics, "bad-slug.json: family and name must"),
	"invalid slug is isolated"
)
h.truthy(
	contains(inventory.diagnostics, "wrong-path.json: family or name does not match"),
	"path mismatch is isolated"
)
h.truthy(
	contains(inventory.diagnostics, "custom.json: name custom is reserved"),
	"custom is reserved"
)
h.truthy(
	contains(inventory.diagnostics, "broken.json: unknown field invalid"),
	"malformed record is isolated"
)
h.truthy(
	contains(inventory.diagnostics, "unreadable.json: failed to read JSON"),
	"read failures are isolated"
)
h.truthy(
	contains(inventory.diagnostics, "studio-night.json: name is not globally unique"),
	"duplicate names are isolated"
)
h.eq(nil, inventory.themes["studio-night"], "duplicate name is omitted from inventory")
local _, _, manager_diagnostics = themes.inventory()
h.truthy(
	contains(manager_diagnostics, "gruber-dark.json: name collides with a bundled theme"),
	"bundled collision reaches manager diagnostics"
)
