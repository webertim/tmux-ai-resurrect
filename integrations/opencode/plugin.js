// tmux-ai-resurrect — opencode integration.
//
// Subscribes to opencode session events and pushes the current session ID
// into the pane cache managed by the CLI. On tmux restore, the resurrect
// hook picks up that ID and relaunches opencode with `--session <id>`.

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

function extractSessionID(event) {
	const props = event?.properties;
	if (!props) return null;
	if (props.info && typeof props.info.id === "string") return props.info.id;
	if (typeof props.sessionID === "string") return props.sessionID;
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
