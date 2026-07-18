#!/usr/bin/env node
import { existsSync, mkdirSync, readFileSync, writeFileSync } from "node:fs";
import { dirname, join, resolve } from "node:path";
import { fileURLToPath } from "node:url";

const scriptDirectory = dirname(fileURLToPath(import.meta.url));
const repositoryRoot = resolve(scriptDirectory, "..", "..");

function loadThemes() {
	const registry = readFileSync(join(repositoryRoot, "lua/neotheme/themes/init.lua"), "utf8");
	const pattern = /\["([^"]+)"\]\s*=\s*\{[^}]*module\s*=\s*"([^"]+)"[^}]*\}/g;
	const result = {};
	for (const [, name, moduleName] of registry.matchAll(pattern)) {
		result[name] = {
			displayName: name
				.split("-")
				.map((part) => part[0].toUpperCase() + part.slice(1))
				.join(" "),
			source: `lua/${moduleName.replaceAll(".", "/")}.lua`,
		};
	}
	if (Object.keys(result).length === 0) {
		throw new Error("Could not read built-in themes from lua/neotheme/themes/init.lua");
	}
	return result;
}

const themes = loadThemes();

const labels = {
	surface_deepest: "Deepest",
	surface_dark: "Dark",
	surface_base: "Base",
	surface_raised: "Raised",
	surface_selected: "Selected",
	surface_border: "Border",
	surface_muted: "Muted",
	surface_addition: "Addition",
	surface_error: "Surface error",
	text_primary: "Text",
	text_bright: "Bright text",
	text_strong: "Strong text",
	text_muted: "Muted text",
	text_on_accent: "On accent",
	text_on_error: "On error",
	syntax_comment: "Comment",
	syntax_string: "String",
	syntax_keyword: "Keyword",
	syntax_function_name: "Function",
	syntax_type: "Type",
	syntax_property: "Property",
	syntax_literal: "Literal",
	diagnostic_error: "Diagnostic",
	version_control_conflict: "Conflict",
};

function usage() {
	return `Usage: docs/scripts/generate-palette-cards.sh [options] [theme ...]

Generate the SVG palette cards for all built-in themes backed by the simplified
palette schema, or only the named public theme(s). --check verifies that the
selected output cards are current and exits non-zero when regeneration is needed.

Options:
  --check            Verify instead of writing.
  --output-dir PATH  Write a flat set of temporary cards to PATH.
  -h, --help         Show this help.`;
}

function parseArguments(arguments_) {
	let check = false;
	let outputDirectory;
	const requestedThemes = [];

	for (let index = 0; index < arguments_.length; index += 1) {
		const argument = arguments_[index];
		if (argument === "--check") {
			check = true;
			continue;
		}
		if (argument === "--output-dir") {
			const value = arguments_[index + 1];
			if (value === undefined) throw new Error("--output-dir requires a path");
			outputDirectory = resolve(value);
			index += 1;
			continue;
		}

		if (argument === "--help" || argument === "-h") {
			console.log(usage());
			process.exit(0);
		}

		if (argument.startsWith("-")) {
			throw new Error(`Unknown option: ${argument}`);
		}

		if (!Object.hasOwn(themes, argument)) {
			throw new Error(`Unknown theme: ${argument}`);
		}

		if (!requestedThemes.includes(argument)) {
			requestedThemes.push(argument);
		}
	}
	if (outputDirectory === undefined) {
		throw new Error("--output-dir is required; use generate-theme-assets.sh for final assets");
	}

	return {
		check,
		outputDirectory,
		themeNames: requestedThemes.length === 0 ? Object.keys(themes) : requestedThemes,
	};
}

function textColor(hex) {
	const value = hex.slice(1);
	const red = Number.parseInt(value.slice(0, 2), 16);
	const green = Number.parseInt(value.slice(2, 4), 16);
	const blue = Number.parseInt(value.slice(4, 6), 16);
	const luminance = (red * 299 + green * 587 + blue * 114) / 1000;
	return luminance > 150 ? "#211d19" : "#fffaf4";
}

function escapeXml(value) {
	return value
		.replaceAll("&", "&amp;")
		.replaceAll("<", "&lt;")
		.replaceAll(">", "&gt;")
		.replaceAll('"', "&quot;")
		.replaceAll("'", "&apos;");
}

function configuredColors(themeName) {
	const theme = themes[themeName];
	const sourcePath = join(repositoryRoot, theme.source);
	const source = readFileSync(sourcePath, "utf8");
	const simplifiedStart = source.indexOf("local simplified = {");
	const simplifiedEnd = source.indexOf("\n}", simplifiedStart);

	if (simplifiedStart === -1 || simplifiedEnd === -1) {
		throw new Error(`Could not find the simplified palette in ${theme.source}`);
	}

	const simplified = source.slice(simplifiedStart, simplifiedEnd);
	const pattern = /^[ \t]*([a-z_][a-z0-9_]*)[ \t]*=[ \t]*"(#[0-9a-fA-F]{6})",[ \t]*$/gm;
	const colors = [];
	const seen = new Set();

	for (const match of simplified.matchAll(pattern)) {
		const [, key, color] = match;
		if (!Object.hasOwn(labels, key)) {
			throw new Error(`Unknown simplified palette color ${key} in ${themeName}`);
		}

		const normalizedColor = color.toUpperCase();
		if (!seen.has(normalizedColor)) {
			seen.add(normalizedColor);
			colors.push({ key, color: normalizedColor, label: labels[key] });
		}
	}

	if (colors.length === 0) {
		throw new Error(`No configured colors found for ${themeName}`);
	}

	return colors;
}

function labelLines(label) {
	const words = label.split(" ");
	return words.length === 1 ? [label] : [words.slice(0, -1).join(" "), words.at(-1)];
}

function svgFor(themeName, colors) {
	const { displayName } = themes[themeName];
	const columns = 6;
	const tileSize = 140;
	const gap = 8;
	const margin = 24;
	const headerHeight = 72;
	const titleBoxPadding = 16;
	const titleBoxWidth = Math.max(tileSize, displayName.length * 14 + titleBoxPadding * 2);
	const rows = Math.ceil(colors.length / columns);
	const width = margin * 2 + columns * tileSize + (columns - 1) * gap;
	const height = headerHeight + margin + rows * tileSize + (rows - 1) * gap + margin;

	const squares = colors
		.map((tile, index) => {
			const column = index % columns;
			const row = Math.floor(index / columns);
			const x = margin + column * (tileSize + gap);
			const y = headerHeight + margin + row * (tileSize + gap);
			const foreground = textColor(tile.color);
			const lines = labelLines(tile.label);
			const label = lines
				.map(
					(line, lineIndex) =>
						`<tspan x="${x + tileSize / 2}" dy="${lineIndex === 0 ? 0 : 16}">${escapeXml(line)}</tspan>`,
				)
				.join("");

			return `
			<g aria-label="${escapeXml(tile.key)}">
				<rect x="${x}" y="${y}" width="${tileSize}" height="${tileSize}" rx="4" fill="${tile.color}" />
				<text x="${x + tileSize / 2}" y="${y + (lines.length === 1 ? 64 : 56)}" text-anchor="middle" fill="${foreground}" font-family="ui-sans-serif, system-ui, sans-serif" font-size="13" font-weight="650">${label}</text>
				<text x="${x + tileSize / 2}" y="${y + 118}" text-anchor="middle" fill="${foreground}" fill-opacity="0.78" font-family="ui-monospace, SFMono-Regular, Menlo, Consolas, monospace" font-size="10">${tile.color}</text>
			</g>`;
		})
		.join("");

	return `<svg xmlns="http://www.w3.org/2000/svg" width="${width}" height="${height}" viewBox="0 0 ${width} ${height}" role="img" aria-labelledby="title description">
	<title id="title">${escapeXml(displayName)} simplified palette</title>
	<desc id="description">${colors.length} configured colors from the shared simplified palette.</desc>
	<rect width="100%" height="100%" fill="#1b1b1b" rx="12" />
	<rect x="${margin}" y="12" width="${titleBoxWidth}" height="58" rx="4" fill="#292929" />
	<text x="${margin + titleBoxPadding}" y="39" fill="#f5efe6" font-family="ui-monospace, SFMono-Regular, Menlo, Consolas, monospace" font-size="20" font-weight="700">${escapeXml(displayName)}</text>
	<text x="${margin + titleBoxPadding}" y="58" fill="#cfc5b8" font-family="ui-sans-serif, system-ui, sans-serif" font-size="11">Simplified palette</text>${squares}
</svg>`;
}

function outputPath(themeName, outputDirectory) {
	return join(outputDirectory, `${themeName}.svg`);
}

function generate({ check, outputDirectory, themeNames }) {
	const stalePaths = [];

	for (const themeName of themeNames) {
		const svg = svgFor(themeName, configuredColors(themeName));
		const destination = outputPath(themeName, outputDirectory);

		if (check) {
			if (!existsSync(destination) || readFileSync(destination, "utf8") !== svg) {
				stalePaths.push(destination);
			}
			continue;
		}

		mkdirSync(dirname(destination), { recursive: true });
		writeFileSync(destination, svg, "utf8");
		console.log(`Generated ${destination}`);
	}

	if (check && stalePaths.length > 0) {
		for (const stalePath of stalePaths) {
			console.error(`Palette card is out of date: ${stalePath}`);
		}
		console.error("Run docs/scripts/generate-palette-cards.sh with the same --output-dir.");
		process.exitCode = 1;
	} else if (check) {
		console.log("Palette cards are current.");
	}
}

try {
	generate(parseArguments(process.argv.slice(2)));
} catch (error) {
	console.error(error.message);
	process.exitCode = 1;
}
