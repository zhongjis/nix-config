import { exec } from "herdr";
import { tokenOutput, httpReason } from "./logic.js";

// A client belongs to one saved configuration. Its token never enters storage.
export function client(config) {
  let token;
  return async (url, options = {}) => {
    if (!token) {
      const result = await exec("zsh", ["-c", config.tokenCommand]);
      // stderr can contain command output; never surface it (or the token).
      if (result.code !== 0) throw new Error(`Token command exited with code ${result.code}.`);
      token = tokenOutput(result.stdout);
    }
    const response = await fetch(url, {
      ...options,
      headers: {
        Accept: "application/json", "Content-Type": "application/json",
        Authorization: config.provider === "jira" ? `Bearer ${token}` : token,
      },
    });
    // Fetch's TLS/network errors propagate unchanged; no curl fallback.
    if (!response.ok) throw new Error(httpReason(response.status, await response.text()));
    return response.status === 204 ? null : response.json();
  };
}
