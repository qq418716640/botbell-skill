# BotBell Skill

Send push notifications to your iPhone/Mac from AI coding agents — and get replies.

Works with [Claude Code](https://claude.ai/code), [GitHub Copilot](https://github.com/features/copilot), [Cursor](https://cursor.com), [OpenAI Codex](https://openai.com/codex), [Gemini CLI](https://github.com/google-gemini/gemini-cli), and any tool that supports [Agent Skills](https://agentskills.io).

## What it does

Once installed, your AI assistant can:

- **Notify you** when a long task finishes (tests, builds, deploys)
- **Ask for confirmation** before risky operations (delete, force push, deploy to production)
- **Send reports** (code review, analysis results) to your phone
- **Ask questions** and wait for your reply to continue

## Install

```bash
npx skills add qq418716640/botbell-skill
```

## Prerequisites

- `curl` and `jq` must be installed on your machine

## Setup

1. Download [BotBell](https://botbell.app) from the App Store
2. Create a Bot and copy its token
3. Set the environment variable:

```bash
export BOTBELL_TOKEN="bt_your_token_here"
```

## Usage

Just tell your AI assistant what you want:

- "Run the tests and notify me when done"
- "Deploy to production, but confirm with me first"
- "Review this code and send the summary to my phone"
- "Ask me which config to use"

The skill handles the rest — your AI knows when and how to notify you.

## Manual command

You can also invoke directly:

```
/botbell run the migration and let me know the result
```

## Need more?

For multi-bot management, PAT authentication, and deeper integration, use the [BotBell MCP Server](https://github.com/qq418716640/botbell-mcp).

## Links

- [BotBell Website](https://botbell.app)
- [BotBell MCP Server](https://github.com/qq418716640/botbell-mcp)
- [API Documentation](https://botbell.app/docs/api)
