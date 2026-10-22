// Run: bun codex-provider-errors.mjs /path/to/@earendil-works/pi-ai
import assert from "node:assert/strict";
import { resolve } from "node:path";
import { pathToFileURL } from "node:url";

const { stream } = await import(pathToFileURL(resolve(process.argv[2], "dist/api/openai-codex-responses.js")).href);
const model = {
  id: "test-codex", provider: "openai-codex", api: "openai-codex-responses",
  baseUrl: "https://codex.invalid", reasoning: false, input: ["text"],
  cost: { input: 0, output: 0, cacheRead: 0, cacheWrite: 0 },
  contextWindow: 1000, maxTokens: 100,
};
const apiKey = `fake.${Buffer.from(JSON.stringify({
  "https://api.openai.com/auth": { chatgpt_account_id: "test-account" },
})).toString("base64url")}.fake`;
const context = { messages: [{ role: "user", content: "hi", timestamp: 0 }] };
const options = { apiKey, transport: "sse", maxRetries: 0 };
const failures = (message) => message.diagnostics?.filter((d) => d.type === "provider_response_failure") ?? [];
const httpError = (status, error) => new Response(JSON.stringify({ error, privatePayload: "do-not-retain" }), { status });
const sse = (event) => new Response(`data: ${JSON.stringify(event)}\n\n`, {
  headers: { "content-type": "text/event-stream" },
});

const http = await stream(model, context, {
  ...options,
  fetch: async () => httpError(429, { code: "usage_limit_reached", type: "quota_error", message: "Request refused" }),
}).result();
assert.equal(http.stopReason, "error");
assert.equal(http.errorMessage, "You have hit your ChatGPT usage limit.");
assert.equal(failures(http).length, 1);
assert.deepEqual(failures(http)[0].details, { status: 429, errorCode: "usage_limit_reached", errorType: "quota_error" });
assert.ok(!JSON.stringify(http.diagnostics).includes("do-not-retain"));

for (const event of [
  { type: "error", code: "usage_limit_reached", message: "Request refused" },
  { type: "error", error: { code: "usage_limit_reached", type: "quota_error", message: "Request refused" } },
  { type: "response.failed", response: { error: { code: "usage_limit_reached", type: "quota_error", message: "Request refused" } } },
]) {
  const message = await stream(model, context, { ...options, fetch: async () => sse(event) }).result();
  assert.equal(message.stopReason, "error");
  assert.equal(failures(message).length, 1);
  assert.deepEqual(failures(message)[0].details, {
    errorCode: "usage_limit_reached",
    ...(event.type === "error" && !event.error ? {} : { errorType: "quota_error" }),
  });
  assert.equal(message.errorMessage, event.type === "error" ? "Codex error: Request refused" : "Request refused");
}

const network = await stream(model, context, {
  ...options, fetch: async () => { throw new TypeError("fetch failed"); },
}).result();
assert.equal(network.errorMessage, "fetch failed");
assert.deepEqual(failures(network), []);

const nonJson = await stream(model, context, {
  ...options, fetch: async () => new Response("Unavailable", { status: 503 }),
}).result();
assert.equal(nonJson.errorMessage, "Unavailable");
assert.deepEqual(failures(nonJson)[0].details, { status: 503 });

const unstructured = await stream(model, context, {
  ...options, fetch: async () => httpError(403, { code: { nested: true }, type: 42, message: "Forbidden" }),
}).result();
assert.deepEqual(failures(unstructured)[0].details, { status: 403 });
assert.equal(unstructured.errorMessage, "Forbidden");

let requests = 0;
const retried = await stream(model, context, {
  ...options, maxRetries: 1,
  fetch: async () => {
    requests++;
    return requests === 1
      ? new Response("retry", { status: 503, headers: { "retry-after-ms": "0" } })
      : sse({ type: "response.completed", response: { status: "completed", output: [] } });
  },
}).result();
assert.equal(requests, 2);
assert.equal(retried.stopReason, "stop");
assert.deepEqual(failures(retried), []);
console.log("Codex real-adapter structured-error checks passed");
