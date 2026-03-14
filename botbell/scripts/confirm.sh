#!/usr/bin/env bash
# BotBell confirm — send a message and wait for user reply
# Usage:
#   confirm.sh <message> [title]                    → free text reply
#   confirm.sh <message> [title] --actions "Yes,No"  → button reply
#   confirm.sh <message> [title] --input "placeholder" → text input button
# Options:
#   --timeout <seconds>  Max wait time (default: 300 = 5 minutes)
#   --interval <seconds> Poll interval (default: 5)
set -euo pipefail

command -v jq >/dev/null 2>&1 || { echo "Error: jq is required but not installed. See https://jqlang.github.io/jq/download/"; exit 1; }
command -v curl >/dev/null 2>&1 || { echo "Error: curl is required but not installed."; exit 1; }

TOKEN="${BOTBELL_TOKEN:?Error: BOTBELL_TOKEN environment variable is not set}"
API_BASE="${BOTBELL_API_BASE:-https://api.botbell.app/v1}"

MESSAGE=""
TITLE=""
ACTIONS=""
INPUT_PLACEHOLDER=""
TIMEOUT=300
INTERVAL=5

# Parse all arguments: first positional is message, second is title, rest are flags
while [[ $# -gt 0 ]]; do
  case "$1" in
    --actions) [[ $# -ge 2 ]] && { ACTIONS="$2"; shift 2; } || shift ;;
    --input) [[ $# -ge 2 ]] && { INPUT_PLACEHOLDER="$2"; shift 2; } || shift ;;
    --timeout) [[ $# -ge 2 ]] && { TIMEOUT="$2"; shift 2; } || shift ;;
    --interval) [[ $# -ge 2 ]] && { INTERVAL="$2"; shift 2; } || shift ;;
    *)
      if [[ -z "$MESSAGE" ]]; then
        MESSAGE="$1"
      elif [[ -z "$TITLE" ]]; then
        TITLE="$1"
      fi
      shift ;;
  esac
done

[[ -n "$MESSAGE" ]] || { echo "Error: message is required"; exit 1; }

# Build actions JSON array
ACTIONS_JSON=""
if [[ -n "$ACTIONS" ]]; then
  ACTIONS_JSON=$(echo "$ACTIONS" | tr ',' '\n' | jq -R '{key: (. | ascii_downcase | gsub(" "; "_")), label: .}' | jq -s '.')
  # Add input option if specified
  if [[ -n "$INPUT_PLACEHOLDER" ]]; then
    ACTIONS_JSON=$(echo "$ACTIONS_JSON" | jq --arg ph "$INPUT_PLACEHOLDER" '. + [{key: "custom_input", label: "Other...", type: "input", placeholder: $ph}]')
  fi
elif [[ -n "$INPUT_PLACEHOLDER" ]]; then
  ACTIONS_JSON=$(jq -n --arg ph "$INPUT_PLACEHOLDER" '[{key: "custom_input", label: "Reply...", type: "input", placeholder: $ph}]')
fi

# Build JSON body
BODY=$(jq -n \
  --arg message "$MESSAGE" \
  --arg title "$TITLE" \
  --argjson actions "${ACTIONS_JSON:-null}" \
  '{message: $message}
   + (if $title != "" then {title: $title} else {} end)
   + (if $actions != null then {actions: $actions, reply_mode: "actions_only"} else {} end)')

# Send the notification
RESPONSE=$(curl -s -w "\n%{http_code}" -X POST "${API_BASE}/push/${TOKEN}" \
  -H "Content-Type: application/json" \
  -d "$BODY") || { echo "Error: Failed to connect to ${API_BASE}"; exit 1; }

HTTP_CODE=$(echo "$RESPONSE" | tail -1)
RESPONSE_BODY=$(echo "$RESPONSE" | sed '$d')

if [[ "$HTTP_CODE" -lt 200 || "$HTTP_CODE" -ge 300 ]]; then
  echo "Failed to send notification (HTTP $HTTP_CODE)" >&2
  echo "$RESPONSE_BODY" | jq -r '.message // .error // .' 2>/dev/null >&2 || echo "$RESPONSE_BODY" >&2
  exit 1
fi

MESSAGE_ID=$(echo "$RESPONSE_BODY" | jq -r '.data.message_id' 2>/dev/null)
echo "Notification sent (ID: $MESSAGE_ID). Waiting for reply..." >&2

# Poll for reply
ELAPSED=0
while [[ $ELAPSED -lt $TIMEOUT ]]; do
  sleep "$INTERVAL"
  ELAPSED=$((ELAPSED + INTERVAL))

  POLL_RESPONSE=$(curl -s "${API_BASE}/messages/poll?limit=1&reply_to=${MESSAGE_ID}" \
    -H "X-Bot-Token: ${TOKEN}") || continue

  MESSAGES=$(echo "$POLL_RESPONSE" | jq -r '.data.messages // []' 2>/dev/null) || continue
  COUNT=$(echo "$MESSAGES" | jq 'length' 2>/dev/null) || continue

  if [[ "$COUNT" -gt 0 ]]; then
    REPLY=$(echo "$MESSAGES" | jq '.[0]')
    if [[ "$REPLY" != "null" ]]; then
      CONTENT=$(echo "$REPLY" | jq -r '.content // ""')
      ACTION=$(echo "$REPLY" | jq -r '.action // ""')
      if [[ -n "$ACTION" && "$ACTION" != "null" ]]; then
        echo "REPLY_ACTION=$ACTION"
        echo "REPLY_CONTENT=$CONTENT"
      else
        echo "REPLY_CONTENT=$CONTENT"
      fi
      exit 0
    fi
  fi
done

echo "Timed out waiting for reply after ${TIMEOUT}s" >&2
exit 2
