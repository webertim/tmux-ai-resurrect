// tmux-ai-resurrect — opencode integration (TUI side).
//
// Catches session switches the server-side plugin misses — most notably
// selecting an existing session via `/sessions`, which changes the TUI
// route but does not always emit a server event our shape checks
// recognise.
//
// Two mechanisms:
//   1. Subscribe to session lifecycle events via api.event.on.
//   2. Poll api.route.current every 750ms; whenever the pane is showing
//      a session route, record its sessionID.

import { writeSession, extractSessionID } from "./tmux-ai-resurrect.js";

const TMUX_PANE = process.env.TMUX_PANE || "";
const ROUTE_POLL_MS = 750;

export default {
	tui: async (api) => {
		if (!TMUX_PANE) return;

		const onEvent = (event) => {
			const id = extractSessionID(event);
			if (id) writeSession(id);
		};

		for (const type of [
			"session.created",
			"session.updated",
			"session.idle",
			"session.status",
		]) {
			try { api.event.on(type, onEvent); } catch {}
		}

		const pollRoute = () => {
			try {
				const r = api.route?.current;
				if (r?.name === "session" && typeof r?.params?.sessionID === "string") {
					writeSession(r.params.sessionID);
				}
			} catch {}
		};
		const intervalId = setInterval(pollRoute, ROUTE_POLL_MS);
		pollRoute();

		const dispose = () => clearInterval(intervalId);
		api.lifecycle?.onDispose?.(dispose);
		api.lifecycle?.signal?.addEventListener?.("abort", dispose, { once: true });
	},
};
