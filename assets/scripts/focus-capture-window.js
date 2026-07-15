const captureTitlePrefix = "neotheme.nvim - ";

for (const window of workspace.windowList()) {
	if (window.caption && window.caption.startsWith(captureTitlePrefix)) {
		workspace.activeWindow = window;
		break;
	}
}
