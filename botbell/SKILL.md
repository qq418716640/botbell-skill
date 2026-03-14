---
name: botbell
description: >
  Send push notifications to the user's phone and get replies via BotBell.
  Use when: a long-running task completes (tests, builds, deployments),
  you need the user's confirmation before a risky operation (delete, force push, deploy to production),
  you want to send analysis results or reports to the user's phone,
  or you need to ask the user a question and wait for their response.
  Trigger words: notify, alert, tell me, send to phone, confirm, approve, ask me, wait for reply.
allowed-tools: Bash Read
---

# BotBell — Push Notifications for AI Coding Agents

Send notifications to the user's iPhone/Mac and get their replies, all from within your coding session.

## Prerequisites Check

**Before doing anything else, verify the environment:**

```bash
echo "${BOTBELL_TOKEN:?}"
```

If `BOTBELL_TOKEN` is not set, stop and tell the user:

> To use BotBell, set your Bot Token as an environment variable:
>
> ```bash
> export BOTBELL_TOKEN="bt_your_token_here"
> ```
>
> Get your token from the BotBell app (App Store) — create a Bot, then copy its token.

Do NOT proceed until the token is configured.

## Scripts

Three scripts are in the `scripts/` subdirectory next to this file. Determine the absolute path to the scripts directory from this SKILL.md file's location, then call them with `bash <path>/scripts/<script>`.

| Script | Purpose | Usage |
|--------|---------|-------|
| `send.sh` | Send a notification (fire and forget) | `send.sh <message> [title] [--url URL] [--format markdown]` |
| `confirm.sh` | Send and wait for reply | `confirm.sh <message> [title] [--actions "Yes,No"] [--input "placeholder"] [--timeout 300]` |
| `poll.sh` | Check for new replies | `poll.sh [limit]` |

**All scripts require `jq` and `curl` to be installed.**

## Usage Scenarios

In all examples below, `SCRIPTS` refers to the absolute path to the `scripts/` directory.

### 1. Notify after a long task

When the user asks you to run tests, build, deploy, or any task that takes a while, send the result summary when done.

**Example:** User says "run the tests and let me know"

```bash
# Run the task first
npm test 2>&1 | tee /tmp/test-output.txt

# Summarize and notify
bash SCRIPTS/send.sh "All 58 tests passed in 4.2s" "Test Results"
```

**Example:** User says "deploy to staging and notify me"

```bash
# Run deployment
fly deploy --app myapp-staging 2>&1 | tee /tmp/deploy.log

# Notify with result
bash SCRIPTS/send.sh "Staging deploy complete. v2.3.1 is live." "Deploy"
```

### 2. Confirm before risky operations

When you're about to do something destructive or irreversible, ask for confirmation first.

**Example:** User says "clean up the old branches" — before deleting, confirm:

```bash
RESULT=$(bash SCRIPTS/confirm.sh \
  "Delete 12 merged branches? (main and develop are protected)" \
  "Branch Cleanup" \
  --actions "Yes,No")

if echo "$RESULT" | grep -q "REPLY_ACTION=yes"; then
  # User approved, proceed with deletion
  git branch --merged | grep -v 'main\|develop' | xargs git branch -d
else
  echo "User declined. Skipping branch cleanup."
fi
```

### 3. Ask a question and wait for answer

When you need the user's input to continue.

**Example:** Multiple options to choose from:

```bash
RESULT=$(bash SCRIPTS/confirm.sh \
  "Found 3 matching configs. Which one should I use?" \
  "Config Selection" \
  --actions "production,staging,development")

ACTION=$(echo "$RESULT" | grep "REPLY_ACTION=" | cut -d= -f2)
echo "User selected: $ACTION"
```

**Example:** Free text input needed:

```bash
RESULT=$(bash SCRIPTS/confirm.sh \
  "What should the new API endpoint be named?" \
  "Naming" \
  --input "e.g. /v1/users/export")

CONTENT=$(echo "$RESULT" | grep "REPLY_CONTENT=" | cut -d= -f2-)
echo "User replied: $CONTENT"
```

### 4. Send analysis or report

When the user asks for a code review, analysis, or summary to be sent to their phone.

**Example:** User says "review this PR and send me the summary"

First do the analysis, compose the summary as a variable, then send:

```bash
SUMMARY="PR #42 Review

3 issues found:
- SQL injection in UserController L45
- Missing null check in OrderService L123
- Unused import in Utils.java

No blocking issues."

bash SCRIPTS/send.sh "$SUMMARY" "Code Review"
```

For markdown formatting, add `--format markdown`.

### 5. Check for replies

When the user asks if there are any new messages.

```bash
bash SCRIPTS/poll.sh
```

## Behavior Guidelines

1. **Summarize, don't dump** — Send a concise summary, not raw logs. Users read notifications on their phone.
2. **Title is important** — Always include a short title so the notification preview is useful.
3. **Use confirm for irreversible actions** — Deleting files, force pushing, deploying to production, dropping tables.
4. **Don't over-notify** — One notification per task completion is enough. Don't send progress updates unless explicitly asked.
5. **Timeout handling** — If `confirm.sh` times out (exit code 2), tell the user you didn't get a response and ask what to do next.
6. **Error handling** — If a script fails (exit code 1), report the error to the user in the conversation. Don't retry silently.
