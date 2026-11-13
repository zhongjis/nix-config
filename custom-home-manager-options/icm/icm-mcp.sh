# icm-mcp: the `icm` CLI subset agents use, sent to the ICM daemon over MCP so the
# daemon's loaded embedding model is reused instead of loading one per call.
# Same syntax as `icm <command>`. Runs `icm "$@"` instead when the daemon can't be
# reached, or for commands and flags not mapped here.

fallback() { exec icm "$@"; }

descriptor="${XDG_CONFIG_HOME:-$HOME/.config}/icm/daemon.json"
url="$(jq -r '.url // empty' "$descriptor" 2>/dev/null || true)"
[ -n "$url" ] || fallback "$@"

# Comma-separated keywords as a JSON array.
keywords() { jq -cn --arg k "$1" '$k | split(",") | map(select(. != ""))'; }

cmd="${1:-}"
[ "$#" -gt 0 ] && shift
args='{}'
set_str() { args="$(jq -c --arg k "$1" --arg v "$2" '.[$k] = $v' <<<"$args")"; }
set_json() { args="$(jq -c --arg k "$1" --argjson v "$2" '.[$k] = $v' <<<"$args")"; }

case "$cmd" in
  recall) tool=icm_memory_recall ;;
  store) tool=icm_memory_store ;;
  update) tool=icm_memory_update ;;
  forget) tool=icm_memory_forget ;;
  topics) tool=icm_memory_list_topics ;;
  *) fallback "$cmd" "$@" ;;
esac

original=("$cmd" "$@")
# The daemon filters recall by its own cwd's project unless told otherwise; the CLI doesn't filter.
[ "$cmd" = recall ] && set_str project ""
while [ "$#" -gt 0 ]; do
  flag="$1"
  case "$cmd:$flag" in
    recall:-t | recall:--topic) set_str topic "$2" ;;
    recall:-l | recall:--limit) set_json limit "$2" ;;
    recall:-k | recall:--keyword) set_str keyword "$2" ;;
    recall:-p | recall:--project) set_str project "$2" ;;
    store:-t | store:--topic) set_str topic "$2" ;;
    store:-c | store:--content | update:-c | update:--content) set_str content "$2" ;;
    store:-i | store:--importance | update:-i | update:--importance) set_str importance "$2" ;;
    store:-k | store:--keywords | update:-k | update:--keywords) set_json keywords "$(keywords "$2")" ;;
    recall:-* | store:-* | update:-* | forget:-* | topics:-*) fallback "${original[@]}" ;;
    recall:*) set_str query "$flag"; shift; continue ;;
    update:* | forget:*) set_str id "$flag"; shift; continue ;;
    *) fallback "${original[@]}" ;;
  esac
  [ "$#" -ge 2 ] || fallback "${original[@]}"
  shift 2
done

request="$(jq -cn --arg tool "$tool" --argjson args "$args" \
  '{jsonrpc: "2.0", id: 1, method: "tools/call", params: {name: $tool, arguments: $args}}')"

set +e
reply="$(curl -s --max-time 60 -X POST "$url" -H 'Content-Type: application/json' --data-binary "$request")"
status=$?
set -e
# 7: connection refused, nothing was sent, so the CLI may run instead. Other failures
# may already have committed (a store), so they are reported, never replayed.
[ "$status" -eq 7 ] && fallback "${original[@]}"
if [ "$status" -ne 0 ]; then
  echo "icm-mcp: daemon request failed (curl exit $status)" >&2
  exit 1
fi

jq -r '.error.message // (.result.content // [] | map(.text // empty) | join("\n"))' <<<"$reply"
jq -e '(.error == null) and (.result.isError != true)' <<<"$reply" >/dev/null
