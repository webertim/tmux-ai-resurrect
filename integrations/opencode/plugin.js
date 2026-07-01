// tmux-ai-resurrect — opencode integration (server side).
//
// Subscribes to opencode's server-side session events and forwards the
// current session ID to the tmux-ai-resurrect CLI. The TUI companion
// (tui.js) additionally polls the active route to catch session switches
// that don't surface as a server event our shape checks recognise
// (e.g. selecting a session via /sessions).

import { spawn } from "node:child_process";
import { realpathSync } from "node:fs";
import { fileURLToPath } from "node:url";
import { dirname, join } from "node:path";

const HERE = dirname(realpathSync(fileURLToPath(import.meta.url)));
const CLI = join(HERE, "..", "..", "bin", "tmux-ai-resurrect");
const TMUX_PANE = process.env.TMUX_PANE || "";

let lastSessionID = "";

function writeSession(sessionID) {
	if (!TMUX_PANE) return;
	if (typeof sessionID !== "string" || !sessionID.startsWith("ses_")) return;
	if (sessionID === lastSessionID) return;
	lastSessionID = sessionID;
	spawn(
		CLI,
		["set", "--harness", "opencode", "--session-id", sessionID],
		{ stdio: "ignore", detached: true },
	).unref();
}

// Event payloads can carry the session id in a few different shapes
// depending on opencode version and event type. Try them all rather than
// hard-coding one — the cost is a couple of extra property lookups.
function extractSessionID(event) {
	const props = event?.properties;
	if (!props) return null;
	const candidates = [
		props.sessionID,
		props?.info?.id,
		props?.session?.id,
		props.id,
	];
	for (const v of candidates) {
		if (typeof v === "string" && v.startsWith("ses_")) return v;
	}
	return null;
}

export const TmuxAiResurrect = async () => {
	if (!TMUX_PANE) return {};
	return {
		event: async ({ event }) => {
			const id = extractSessionID(event);
			if (id) writeSession(id);
		},
		"chat.message": async ({ sessionID }) => {
			writeSession(sessionID);
		},
	};
};
