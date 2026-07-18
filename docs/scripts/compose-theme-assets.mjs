#!/usr/bin/env node

import {
	accessSync,
	constants,
	copyFileSync,
	existsSync,
	mkdirSync,
	mkdtempSync,
	readFileSync,
	readdirSync,
	realpathSync,
	rmSync,
	statSync,
} from "node:fs";
import path from "node:path";
import { fileURLToPath, pathToFileURL } from "node:url";
import { spawnSync } from "node:child_process";

const scriptDirectory = path.dirname(fileURLToPath(import.meta.url));
const repositoryRoot = realpathSync(path.join(scriptDirectory, "../.."));
const docsRoot = path.join(repositoryRoot, "docs/themes");

const dimensions = {
	editor: [960, 746],
	palette: [928, 704],
	frame: [2000, 778],
};
const framesPerSecond = 30;
const holdSeconds = 5;
const transitionSeconds = 0.5;
const motionSeconds = transitionSeconds - 1 / framesPerSecond;
const matrixGap = 32;

function fail(message) {
	throw new Error(message);
}

function inventory() {
	const rootReadme = readFileSync(path.join(repositoryRoot, "README.md"), "utf8");
	const familyRows = [...rootReadme.matchAll(/^\| ([A-Za-z]+) \| `([^`]+)` \|/gm)];
	if (familyRows.length === 0) {
		fail("Could not read the theme family matrix from README.md");
	}

	return familyRows.map(([, displayName, standout]) => {
		const name = displayName.toLowerCase();
		const readmePath = path.join(docsRoot, name, "README.md");
		const readme = readFileSync(readmePath, "utf8");
		const themes = [...readme.matchAll(/^\| `([^`]+)` \|/gm)].map((match) => match[1]);
		if (themes.length === 0 || !themes.includes(standout)) {
			fail(`Invalid theme matrix: ${path.relative(repositoryRoot, readmePath)}`);
		}
		return { name, standout, themes };
	});
}

function parseArguments(arguments_, families) {
	let check = false;
	let sourceDirectory;
	let ffmpeg;
	let browser;
	let timeout;
	const targets = [];

	for (let index = 0; index < arguments_.length; index += 1) {
		const argument = arguments_[index];
		if (["--source-dir", "--ffmpeg", "--browser", "--timeout"].includes(argument)) {
			const value = arguments_[index + 1];
			if (value === undefined) {
				fail(`${argument} requires a value`);
			}
			index += 1;
			if (argument === "--source-dir") sourceDirectory = path.resolve(value);
			if (argument === "--ffmpeg") ffmpeg = value;
			if (argument === "--browser") browser = value;
			if (argument === "--timeout") timeout = value;
			continue;
		}
		if (argument === "--check") {
			check = true;
			continue;
		}
		if (argument === "--help" || argument === "-h") {
			console.log(`Usage: compose-theme-assets.mjs --source-dir DIR [options] [root|family ...]

Compose temporary <theme>.png and <theme>.svg inputs into the two checked-in
artifacts for each target: a static matrix and an animated WebP carousel.

Options:
  --check          Regenerate without writing and fail on differences.
  --ffmpeg PATH    Select FFmpeg.
  --browser PATH   Select a Chromium-compatible browser.
  --timeout PATH   Select GNU timeout.
  -h, --help       Show this help.`);
			process.exit(0);
		}
		if (argument.startsWith("-")) {
			fail(`Unknown option: ${argument}`);
		}
		targets.push(argument);
	}

	if (sourceDirectory === undefined) {
		fail("--source-dir is required");
	}
	const validTargets = new Set(["root", ...families.map((family) => family.name)]);
	for (const target of targets) {
		if (!validTargets.has(target)) fail(`Unknown target: ${target}`);
	}
	return {
		browser,
		check,
		ffmpeg,
		sourceDirectory,
		targets: new Set(targets.length === 0 ? validTargets : targets),
		timeout,
	};
}

function executable(requested, defaults) {
	for (const command of requested === undefined ? defaults : [requested]) {
		const candidates = command.includes(path.sep)
			? [path.resolve(command)]
			: (process.env.PATH ?? "").split(path.delimiter).map((directory) => path.join(directory, command));
		for (const candidate of candidates) {
			try {
				accessSync(candidate, constants.X_OK);
				return candidate;
			} catch {
				// Keep searching.
			}
		}
	}
	fail(`Executable not found: ${(requested === undefined ? defaults : [requested]).join(", ")}`);
}

function run(command, arguments_, description, acceptedStatuses = [0]) {
	const result = spawnSync(command, arguments_, { encoding: "utf8" });
	if (result.error !== undefined || !acceptedStatuses.includes(result.status)) {
		const details = [result.error?.message, result.stdout, result.stderr]
			.filter(Boolean)
			.join("\n")
			.trim();
		fail(`${description}${details === "" ? "" : `\n${details}`}`);
	}
}

function requireFile(filePath) {
	if (!existsSync(filePath) || statSync(filePath).size === 0) {
		fail(`Missing input: ${filePath}`);
	}
}

function rasterizePalette(commands, sourcePath, outputPath, profilePath) {
	run(
		commands.timeout,
		[
			"--signal=KILL",
			"3s",
			commands.browser,
			"--headless=new",
			"--disable-gpu",
			"--no-sandbox",
			"--disable-background-networking",
			"--disable-breakpad",
			"--disable-component-update",
			"--disable-extensions",
			"--disable-sync",
			"--default-background-color=00000000",
			"--hide-scrollbars",
			"--no-first-run",
			"--force-device-scale-factor=1",
			`--user-data-dir=${profilePath}`,
			"--window-size=928,704",
			`--screenshot=${outputPath}`,
			pathToFileURL(sourcePath).href,
		],
		`Could not rasterize ${path.basename(sourcePath)}`,
		[0, 124, 137],
	);
	requireFile(outputPath);
}

function composeFrame(ffmpeg, editorPath, palettePath, outputPath) {
	const [editorWidth, editorHeight] = dimensions.editor;
	const [paletteWidth, paletteHeight] = dimensions.palette;
	const [frameWidth, frameHeight] = dimensions.frame;
	const paletteX = 1056;
	const paletteY = (frameHeight - paletteHeight) / 2;
	const filter =
		`[0:v]scale=${editorWidth}:${editorHeight}:force_original_aspect_ratio=decrease:flags=lanczos,` +
		`pad=${editorWidth}:${editorHeight}:(ow-iw)/2:(oh-ih)/2:color=black@0,format=rgba[editor];` +
		`[1:v]scale=${paletteWidth}:${paletteHeight}:force_original_aspect_ratio=decrease:flags=lanczos,` +
		`format=rgba,split[palette][shadow-source];` +
		`[shadow-source]pad=960:736:16:16:color=black@0,colorchannelmixer=aa=0.32,` +
		`gblur=sigma=12[shadow];color=c=black@0:s=${frameWidth}x${frameHeight},format=rgba,` +
		`drawbox=x=999:y=32:w=2:h=714:color=0x8f98a3@0.35:t=fill[canvas];` +
		`[canvas][editor]overlay=x=0:y=16:format=auto[with-editor];` +
		`[with-editor][shadow]overlay=x=1040:y=21:format=auto[with-shadow];` +
		`[with-shadow][palette]overlay=x=${paletteX}:y=${paletteY}:format=auto,format=rgba[out]`;
	run(
		ffmpeg,
		["-hide_banner", "-loglevel", "error", "-y", "-i", editorPath, "-i", palettePath,
			"-filter_complex", filter, "-map", "[out]", "-frames:v", "1", outputPath],
		`Could not compose ${path.basename(outputPath)}`,
	);
}

function carouselFilter(frameCount) {
	const [frameWidth, frameHeight] = dimensions.frame;
	const progress = `min(1,(t+${(1 / framesPerSecond).toFixed(6)})/${transitionSeconds})`;
	const eased = `(1-(1-${progress})*(1-${progress})*(1-${progress}))`;
	const incomingScale = `(0.82+0.18*${eased}+0.04*sin(PI*${progress}))`;
	const filters = [];
	const streams = [];

	for (let index = 0; index < frameCount; index += 1) {
		const timelineOffset = index * (holdSeconds + transitionSeconds);
		filters.push(
			`[${index}:v]fps=${framesPerSecond},format=rgba,split=3[hold-source-${index}]` +
				`[out-source-${index}][in-source-${index}]`,
			`[hold-source-${index}]trim=end_frame=1,settb=AVTB,` +
				`setpts=PTS-STARTPTS+${timelineOffset}/TB[hold-${index}]`,
			`[out-source-${index}]trim=duration=${transitionSeconds},setpts=PTS-STARTPTS,` +
				`scale=w='iw*(1-0.18*${eased})':h='ih*(1-0.18*${eased})':eval=frame,` +
				`fade=t=out:st=0:d=${motionSeconds.toFixed(6)}:alpha=1[out-${index}]`,
			`[in-source-${index}]trim=duration=${transitionSeconds},setpts=PTS-STARTPTS,` +
				`scale=w='iw*${incomingScale}':h='ih*${incomingScale}':eval=frame,` +
				`fade=t=in:st=0:d=0.15:alpha=1[in-${index}]`,
		);
	}

	for (let index = 0; index < frameCount; index += 1) {
		const incoming = (index + 1) % frameCount;
		const offset = index * (holdSeconds + transitionSeconds) + holdSeconds;
		filters.push(
			`color=c=black@0:s=${frameWidth}x${frameHeight}:r=${framesPerSecond}:` +
				`d=${transitionSeconds},format=rgba[canvas-${index}]`,
			`[canvas-${index}][out-${index}]overlay=x='-0.12*W*${eased}':y='(H-h)/2':` +
				`shortest=1:format=auto[background-${index}]`,
			`[background-${index}][in-${incoming}]overlay=x='W*(1-${eased})':y='(H-h)/2':` +
				`shortest=1:format=auto,settb=AVTB,` +
				`setpts=PTS-STARTPTS+${offset}/TB[transition-${index}]`,
		);
		streams.push(`[hold-${index}]`, `[transition-${index}]`);
	}

	filters.push(
		`${streams.join("")}interleave=nb_inputs=${streams.length}:duration=longest,` +
			`format=yuva420p[out]`,
	);
	return filters.join(";");
}

function encodeCarousel(ffmpeg, frames, outputPath) {
	const args = ["-hide_banner", "-loglevel", "error", "-y"];
	for (const frame of frames) args.push("-loop", "1", "-framerate", "30", "-i", frame);
	args.push(
		"-filter_complex", carouselFilter(frames.length), "-map", "[out]", "-an",
		"-c:v", "libwebp_anim", "-preset", "text", "-quality", "80",
		"-compression_level", "6", "-loop", "0", "-fps_mode", "passthrough", outputPath,
	);
	run(ffmpeg, args, `Could not generate ${path.basename(outputPath)}`);
}

function encodeMatrix(ffmpeg, frames, outputPath) {
	const [frameWidth, frameHeight] = dimensions.frame;
	const args = ["-hide_banner", "-loglevel", "error", "-y"];
	for (const frame of frames) args.push("-i", frame);
	const filters = frames.map(
		(_, index) => `[${index}:v]format=rgba,pad=${frameWidth}:${frameHeight + matrixGap}:0:0:` +
			`color=black@0[row-${index}]`,
	);
	const rows = frames.map((_, index) => `[row-${index}]`).join("");
	const height = frames.length * (frameHeight + matrixGap) - matrixGap;
	filters.push(`${rows}vstack=inputs=${frames.length},crop=${frameWidth}:${height}:0:0,format=yuva420p[out]`);
	args.push(
		"-filter_complex", filters.join(";"), "-map", "[out]", "-frames:v", "1",
		"-c:v", "libwebp", "-preset", "text", "-quality", "86", "-compression_level", "6", outputPath,
	);
	run(ffmpeg, args, `Could not generate ${path.basename(outputPath)}`);
}

function publish(generatedPath, destinationPath, check) {
	if (check) {
		if (!existsSync(destinationPath) || !readFileSync(generatedPath).equals(readFileSync(destinationPath))) {
			fail(`Missing or stale: ${path.relative(repositoryRoot, destinationPath)}`);
		}
		console.log(`Verified ${path.relative(repositoryRoot, destinationPath)}`);
		return;
	}
	copyFileSync(generatedPath, destinationPath);
	console.log(`Generated ${path.relative(repositoryRoot, destinationPath)}`);
}

function main() {
	const families = inventory();
	const options = parseArguments(process.argv.slice(2), families);
	const commands = {
		browser: executable(options.browser, ["google-chrome", "chromium", "chromium-browser"]),
		ffmpeg: executable(options.ffmpeg, ["ffmpeg"]),
		timeout: executable(options.timeout, ["timeout"]),
	};
	const scratchRoot = path.join(repositoryRoot, ".agent-workspace");
	mkdirSync(scratchRoot, { recursive: true });
	const scratch = mkdtempSync(path.join(scratchRoot, "theme-assets-"));
	const cache = new Map();

	try {
		const frameFor = (theme) => {
			if (cache.has(theme)) return cache.get(theme);
			const editor = path.join(options.sourceDirectory, `${theme}.png`);
			const palette = path.join(options.sourceDirectory, `${theme}.svg`);
			requireFile(editor);
			requireFile(palette);
			const raster = path.join(scratch, `${theme}-palette.png`);
			rasterizePalette(commands, palette, raster, path.join(scratch, `${theme}-chrome`));
			const frame = path.join(scratch, `${theme}-frame.png`);
			composeFrame(commands.ffmpeg, editor, raster, frame);
			cache.set(theme, frame);
			return frame;
		};
		const generate = (name, themes, outputDirectory) => {
			const frames = themes.map(frameFor);
			const carousel = path.join(scratch, `${name}-previews.webp`);
			const matrix = path.join(scratch, `${name}-matrix.webp`);
			encodeCarousel(commands.ffmpeg, frames, carousel);
			encodeMatrix(commands.ffmpeg, frames, matrix);
			publish(carousel, path.join(outputDirectory, `${name}-previews.webp`), options.check);
			publish(matrix, path.join(outputDirectory, `${name}-matrix.webp`), options.check);
		};

		if (options.targets.has("root")) {
			generate("theme-family", families.map((family) => family.standout), docsRoot);
		}
		for (const family of families) {
			if (options.targets.has(family.name)) {
				generate(family.name, family.themes, path.join(docsRoot, family.name));
			}
		}
	} finally {
		rmSync(scratch, { recursive: true, force: true });
		if (readdirSync(scratchRoot).length === 0) rmSync(scratchRoot, { recursive: true });
	}
}

try {
	main();
} catch (error) {
	console.error(error.message);
	process.exitCode = 1;
}
