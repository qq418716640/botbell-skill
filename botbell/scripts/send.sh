#!/usr/bin/env bash
# BotBell send notification
# Usage: send.sh <message> [title] [options...]
#   Options: --url <url> --image <url> --format markdown
set -euo pipefail

command -v jq >/dev/null 2>&1 || { echo "Error: jq is required but not installed. See https://jqlang.github.io/jq/download/"; exit 1; }
command -v curl >/dev/null 2>&1 || { echo "Error: curl is required but not installed."; exit 1; }

TOKEN="${BOTBELL_TOKEN:?Error: BOTBELL_TOKEN environment variable is not set}"
API_BASE="${BOTBELL_API_BASE:-https://api.botbell.app/v1}"

MESSAGE=""
TITLE=""
URL=""
IMAGE_URL=""
FORMAT=""

# Parse all arguments: first positional is message, rest are flags or title
while [[ $# -gt 0 ]]; do
  case "$1" in
    --url) URL="${2:-}"; shift 2 ;;
    --image) IMAGE_URL="${2:-}"; shift 2 ;;
    --format) FORMAT="${2:-}"; shift 2 ;;
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

# Build JSON body
BODY=$(jq -n \
  --arg message "$MESSAGE" \
  --arg title "$TITLE" \
  --arg url "$URL" \
  --arg image_url "$IMAGE_URL" \
  --arg format "$FORMAT" \
  '{message: $message}
   + (if $title != "" then {title: $title} else {} end)
   + (if $url != "" then {url: $url} else {} end)
   + (if $image_url != "" then {image_url: $image_url} else {} end)
   + (if $format != "" then {format: $format} else {} end)')

RESPONSE=$(curl -s -w "\n%{http_code}" -X POST "${API_BASE}/push/${TOKEN}" \
  -H "Content-Type: application/json" \
  -d "$BODY") || { echo "Error: Failed to connect to ${API_BASE}"; exit 1; }

HTTP_CODE=$(echo "$RESPONSE" | tail -1)
RESPONSE_BODY=$(echo "$RESPONSE" | sed '$d')

if [[ "$HTTP_CODE" -ge 200 && "$HTTP_CODE" -lt 300 ]]; then
  echo "Notification sent successfully."
  echo "$RESPONSE_BODY" | jq -r '.data | "Message ID: \(.message_id)\nDelivered: \(.delivered)"' 2>/dev/null || echo "$RESPONSE_BODY"
else
  echo "Failed to send notification (HTTP $HTTP_CODE)"
  echo "$RESPONSE_BODY" | jq -r '.message // .error // .' 2>/dev/null || echo "$RESPONSE_BODY"
  exit 1
fi
