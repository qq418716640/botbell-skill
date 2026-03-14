#!/usr/bin/env bash
# BotBell poll — fetch user replies
# Usage: poll.sh [limit]
set -euo pipefail

command -v jq >/dev/null 2>&1 || { echo "Error: jq is required but not installed. See https://jqlang.github.io/jq/download/"; exit 1; }
command -v curl >/dev/null 2>&1 || { echo "Error: curl is required but not installed."; exit 1; }

TOKEN="${BOTBELL_TOKEN:?Error: BOTBELL_TOKEN environment variable is not set}"
API_BASE="${BOTBELL_API_BASE:-https://api.botbell.app/v1}"

LIMIT="${1:-20}"

RESPONSE=$(curl -s -w "\n%{http_code}" "${API_BASE}/messages/poll?limit=${LIMIT}" \
  -H "X-Bot-Token: ${TOKEN}") || { echo "Error: Failed to connect to ${API_BASE}"; exit 1; }

HTTP_CODE=$(echo "$RESPONSE" | tail -1)
RESPONSE_BODY=$(echo "$RESPONSE" | sed '$d')

if [[ "$HTTP_CODE" -lt 200 || "$HTTP_CODE" -ge 300 ]]; then
  echo "Failed to fetch replies (HTTP $HTTP_CODE)"
  echo "$RESPONSE_BODY" | jq -r '.message // .error // .' 2>/dev/null || echo "$RESPONSE_BODY"
  exit 1
fi

MESSAGES=$(echo "$RESPONSE_BODY" | jq -r '.data.messages // []')
COUNT=$(echo "$MESSAGES" | jq 'length')

if [[ "$COUNT" -eq 0 ]]; then
  echo "No new replies."
else
  echo "${COUNT} new reply(s):"
  echo "$MESSAGES" | jq -r '.[] | "[" + (.timestamp | todate) + "]" + (if .action then " [action:" + .action + "]" else "" end) + (if .reply_to then " [reply_to:" + .reply_to + "]" else "" end) + " " + .content'
fi
